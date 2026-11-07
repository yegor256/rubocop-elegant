# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Forbids local variables that are assigned exactly once and then
# referenced exactly once, since such variables can be inlined at
# the place of their single use without loss of clarity. The cop
# inspects each method body in isolation, ignores compound
# assignments (+=, ||=, &&=), multiple assignments, +for+ loops,
# rescue variables, and assignments embedded into expressions such
# as +if+ or +while+ conditions; only top-level statements of a
# sequence are considered. A variable whose single read sits inside
# a context that does not also enclose the assignment is left alone:
# loops or blocks (+block+, +numblock+, +while+, +until+, +for+) so
# that inlining does not move the right-hand side into a hot path,
# and conditional branches (+if+, +case+, +case_match+, +and+, +or+,
# +rescue+, +resbody+, +ensure+) so that inlining does not change
# whether or when the right-hand side is evaluated. A variable that
# is reassigned, read more than once, never read, or read only
# before its assignment (a parameter or block argument that is
# overwritten later) is left alone too, and so is every variable of
# a method that calls +binding+ or +eval+ on any receiver, evaluates
# a string with +instance_eval+, +class_eval+ or +module_eval+, or
# names any of those with a symbol, since they reach locals by name.
#
# Inlining moves the right-hand side down to the read, so whatever
# ran in between would run before it instead. The variable is
# therefore left alone unless that gap is side-effect free. The gap
# spans the statements between the assignment and the read, and also
# the operands that precede the read inside its own statement.
# Side-effect free means literals, reads of local variables, +self+,
# arrays, hashes, pairs and parenthesized groups of those, as long
# as building them dispatches no method on a value: a hash key must
# be a literal, a range bound a numeric literal or +nil+, and nothing
# may be interpolated into a string, symbol or regexp. Everything
# else is assumed to be observable: method calls, +yield+, blocks,
# and reads of instance, class and global variables, constants and
# back-references, which the right-hand side may itself write.
# A local read in the gap is only side-effect free while the
# right-hand side cannot change that local: neither the right-hand
# side itself, nor, unless it is side-effect free, any block of the
# method it might call, may assign it, whether plainly, through a
# compound or multiple assignment, a named regexp capture, or a
# pattern. The variable is also left alone when its read sits inside
# an assignment to a local that the right-hand side calls as a method
# or assigns, since that local would then already exist where the
# right-hand side lands: the call would turn into a read of it, and a
# block's own variable of that name, or a block's implicit +it+, into
# the outer one.
# Another assignment that this cop inlines too is stepped over when
# its own read comes later, its own gap is clean, and its line is not
# disabled by a directive comment, since both right-hand sides then
# keep their relative order.
#
# Auto-correct inlines the redundant assignment: it replaces the
# single +lvar+ read with the source of the assignment's right-hand
# side, then removes the whole assignment line including its leading
# indent and trailing newline. An assignment that shares its line
# with other code, or whose own source contains the read of another
# redundant variable that this pass may correct as well, is reported
# but not corrected, since removing its line would clobber the other
# rewrite; a later pass picks it up.
# When the read is the value of a Ruby 3.1 shorthand pair, such as
# the +ids+ of +call(ids:)+, key and value share one range, so the
# whole pair is rewritten into its long form +ids: <rhs>+ instead.
# The right-hand side is wrapped in parentheses unless it is already
# a primary expression (literal, variable, parenthesized expression,
# or method call with parentheses or no arguments), so that operator
# precedence at the read site is preserved.
class RuboCop::Cop::Elegant::NoRedundantVariable < RuboCop::Cop::Base
  extend RuboCop::Cop::AutoCorrector
  include RuboCop::Cop::RangeHelp

  MSG = 'Variable "%<name>s" is redundant and must be inlined: it is read only once'
  public_constant :MSG

  STATEMENT_PARENTS = %i[begin kwbegin def defs block numblock].freeze
  public_constant :STATEMENT_PARENTS

  LOOP_TYPES = %i[block numblock while until while_post until_post for].freeze
  public_constant :LOOP_TYPES

  ALWAYS_FIRST_TYPES = %i[if case case_match and or].freeze
  public_constant :ALWAYS_FIRST_TYPES

  ALWAYS_HOIST_TYPES = %i[rescue resbody ensure].freeze
  public_constant :ALWAYS_HOIST_TYPES

  PRIMARY_TYPES = %i[
    int float str sym dstr dsym xstr true false nil array hash regexp
    lvar ivar cvar gvar const self nth_ref back_ref
  ].freeze
  public_constant :PRIMARY_TYPES

  PURE_TYPES = %i[
    int float rational complex str sym true false nil array hash regexp regopt
    irange erange lvar self pair begin
  ].freeze
  public_constant :PURE_TYPES

  LITERAL_TYPES = %i[int float rational complex str sym true false nil].freeze
  public_constant :LITERAL_TYPES

  BOUND_TYPES = %i[int float rational nil].freeze
  public_constant :BOUND_TYPES

  INTERPOLATING_TYPES = %i[dstr dsym xstr regexp].freeze
  public_constant :INTERPOLATING_TYPES

  CLOSURE_TYPES = %i[block numblock itblock].freeze
  public_constant :CLOSURE_TYPES

  INTROSPECTIVE_METHODS = %i[binding eval].freeze
  public_constant :INTROSPECTIVE_METHODS

  EVALUATING_METHODS = %i[instance_eval class_eval module_eval].freeze
  public_constant :EVALUATING_METHODS

  NAMED_GROUP = /\(\?[<']([^>'=!]+)[>']/.freeze
  public_constant :NAMED_GROUP

  def on_def(node)
    check(node.body)
  end

  def on_defs(node)
    check(node.body)
  end

  private

  def check(body)
    return if body.nil?
    return if introspective?(body)
    assigns = Hash.new { |h, k| h[k] = [] }
    reads = Hash.new { |h, k| h[k] = [] }
    tainted = []
    walk(body, assigns, reads, tainted)
    inline(singles(assigns, reads, tainted))
  end

  def singles(assigns, reads, tainted)
    found = {}.compare_by_identity
    assigns.each do |name, nodes|
      next if tainted.include?(name)
      next unless nodes.size == 1
      next unless reads[name].size == 1
      next unless follows?(reads[name].first, nodes.first)
      next if hoisted?(reads[name].first, nodes.first)
      found[nodes.first] = reads[name].first
    end
    found
  end

  def introspective?(body)
    body.each_node(:send, :csend, :sym).any? do |node|
      next (INTROSPECTIVE_METHODS + EVALUATING_METHODS).include?(node.value) if node.sym_type?
      next true if INTROSPECTIVE_METHODS.include?(node.method_name)
      EVALUATING_METHODS.include?(node.method_name) && node.arguments?
    end
  end

  def follows?(read, assign)
    return false if read.each_ancestor.any? { |node| node.equal?(assign) }
    read.source_range.begin_pos >= assign.source_range.end_pos
  end

  def inline(singles)
    candidates = singles.select { |assign, _| solo?(assign) && enabled_line?(assign.first_line) }.compare_by_identity
    hopeful = {}.compare_by_identity
    live = candidates.reject { |assign, read| crossed?(read, assign, candidates, hopeful) }
    movable = candidates.reject { |assign, _| swallows?(assign, live) }.compare_by_identity
    crossings = {}.compare_by_identity
    singles.each do |assign, read|
      next if crossed?(read, assign, movable, crossings)
      register(assign, read, movable.key?(assign))
    end
  end

  def swallows?(assign, singles)
    range = assign.source_range
    singles.any? do |_, read|
      read.source_range.begin_pos > range.begin_pos && read.source_range.end_pos <= range.end_pos
    end
  end

  def register(assign, read, correctable)
    name = assign.children.first
    return add_offense(assign, message: format(MSG, name: name)) unless correctable
    add_offense(assign, message: format(MSG, name: name)) do |corrector|
      corrector.replace(*rewrite(assign.children.last, read))
      corrector.remove(range_by_whole_lines(assign.source_range, include_final_newline: true))
    end
  end

  def rewrite(rhs, read)
    pair = shorthand(read)
    return [read.source_range, inlined(rhs, read)] if pair.nil?
    [pair.source_range, "#{pair.children.first.source}: #{inlined(rhs, read)}"]
  end

  def shorthand(read)
    parent = read.parent
    return if parent.nil? || !parent.pair_type?
    key, value = parent.children
    return unless value.equal?(read)
    return unless key.source_range == value.source_range
    parent
  end

  def solo?(assign)
    range = assign.source_range
    return false unless range.first_line == range.last_line
    range.source_buffer.source_line(range.first_line).strip == range.source.strip
  end

  def inlined(rhs, read)
    return "(#{braced(rhs)})" if wrap?(rhs, read)
    braced(rhs)
  end

  def braced(rhs)
    return "{ #{rhs.source} }" if rhs.hash_type? && rhs.loc.begin.nil?
    rhs.source
  end

  def wrap?(rhs, read)
    return true unless primary?(rhs)
    rhs.hash_type? && bare?(read)
  end

  def primary?(node)
    return true if PRIMARY_TYPES.include?(node.type)
    return !node.loc.begin.nil? || node.arguments.empty? if node.send_type? || node.csend_type?
    node.begin_type? && node.children.size == 1
  end

  def bare?(read)
    parent = read.parent
    return false if parent.nil?
    return false unless parent.send_type? || parent.csend_type?
    parent.loc.begin.nil? && parent.arguments.include?(read)
  end

  def walk(node, assigns, reads, tainted)
    return unless node.is_a?(RuboCop::AST::Node)
    return if node.def_type? || node.defs_type?
    record(node, assigns, reads, tainted)
    node.each_child_node { |child| walk(child, assigns, reads, tainted) }
  end

  def record(node, assigns, reads, tainted)
    if node.op_asgn_type? || node.or_asgn_type? || node.and_asgn_type?
      taint(node.children.first, tainted)
    elsif node.lvasgn_type? && statement?(node)
      assigns[node.children.first] << node
    elsif node.lvar_type?
      reads[node.children.first] << node
    end
  end

  def taint(target, tainted)
    return unless target.is_a?(RuboCop::AST::Node)
    return unless target.lvasgn_type?
    tainted << target.children.first
  end

  def statement?(node)
    return false unless node.children.size == 2
    parent = node.parent
    parent = parent.parent while !parent.nil? && parent.type == :begin && parent.children.size == 1
    return false if parent.nil?
    STATEMENT_PARENTS.include?(parent.type)
  end

  def hoisted?(read, assign)
    boundary = assign.parent
    return true if boundary.nil?
    child = read
    parent = read.parent
    while !parent.nil? && !parent.equal?(boundary)
      return true if LOOP_TYPES.include?(parent.type)
      return true if ALWAYS_HOIST_TYPES.include?(parent.type)
      return true if ALWAYS_FIRST_TYPES.include?(parent.type) && !parent.children.first.equal?(child)
      child = parent
      parent = parent.parent
    end
    parent.nil?
  end

  def crossed?(read, assign, movable, crossings)
    return crossings[assign] if crossings.key?(assign)
    crossings[assign] = scan?(read, assign, movable, crossings)
  end

  def scan?(read, assign, movable, crossings)
    names = clobbers(assign)
    mentions = mentioned(assign.children.last)
    child = read
    loop do
      parent = child.parent
      return true if parent.lvasgn_type? && mentions.include?(parent.children.first)
      return true unless before(parent, child, assign).all? do |node|
        deferred?(node, read, names, movable, crossings)
      end
      return false if parent.equal?(assign.parent)
      child = parent
    end
  end

  def mentioned(rhs)
    names = written(rhs)
    names << :it if rhs.each_node(:itblock).any?
    rhs.each_node(:send) { |call| names << call.method_name if call.receiver.nil? }
    names
  end

  def before(parent, child, assign)
    kids = parent.children
    stop = kids.index { |node| node.equal?(child) }
    return kids[0...stop].grep(RuboCop::AST::Node) unless parent.equal?(assign.parent)
    kids[(kids.index { |node| node.equal?(assign) } + 1)...stop]
  end

  def deferred?(node, read, names, movable, crossings)
    return names.empty? || node.each_node(:lvar).none? { |lvar| names.include?(lvar.children.first) } if pure?(node)
    twin = movable[node]
    return false if twin.nil?
    return false if twin.source_range.begin_pos < read.source_range.begin_pos
    !crossed?(twin, node, movable, crossings)
  end

  def clobbers(assign)
    rhs = assign.children.last
    return [] if pure?(rhs)
    written(rhs) | closures(assign.each_ancestor(:def, :defs).first)
  end

  def closures(scope)
    @closures ||= {}.compare_by_identity
    @closures[scope] ||= scope.each_node(*CLOSURE_TYPES).flat_map { |block| written(block) }
  end

  def written(root)
    root.each_node(:lvasgn, :match_var, :match_with_lvasgn).flat_map do |write|
      next write.children.first unless write.match_with_lvasgn_type?
      write.children.first.content.scan(NAMED_GROUP).map { |(group)| group.to_sym }
    end
  end

  def pure?(node)
    return false unless PURE_TYPES.include?(node.type)
    return false if node.begin_type? && INTERPOLATING_TYPES.include?(node.parent.type)
    return node.each_child_node.all? { |kid| BOUND_TYPES.include?(kid.type) } if node.range_type?
    return LITERAL_TYPES.include?(node.key.type) && pure?(node.value) if node.pair_type?
    node.each_child_node.all? { |kid| pure?(kid) }
  end
end
