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
# is reassigned, read more than once, or never read is left alone
# too.
#
# Inlining moves the right-hand side down to the read, so whatever
# ran in between would run before it instead. The variable is
# therefore left alone unless that gap is side-effect free. The gap
# spans the statements between the assignment and the read, and also
# the operands that precede the read inside its own statement.
# Side-effect free means literals, reads of local variables, +self+,
# arrays, hashes, pairs and parenthesized groups of those. Everything
# else is assumed to be observable: method calls, +yield+, blocks,
# and reads of instance, class and global variables, constants and
# back-references, which the right-hand side may itself write.
# Another assignment that this cop inlines too is stepped over when
# its own read comes later and its own gap is clean, since both
# right-hand sides then keep their relative order.
#
# Auto-correct inlines the redundant assignment: it replaces the
# single +lvar+ read with the source of the assignment's right-hand
# side, then removes the whole assignment line including its leading
# indent and trailing newline. An assignment that shares its line
# with other code, or whose own source contains the read of another
# redundant variable, is reported but not corrected, since removing
# its line would clobber the other rewrite; a later pass picks it up.
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

  def on_def(node)
    check(node.body)
  end

  def on_defs(node)
    check(node.body)
  end

  private

  def check(body)
    return if body.nil?
    assigns = Hash.new { |h, k| h[k] = [] }
    reads = Hash.new { |h, k| h[k] = [] }
    tainted = []
    walk(body, assigns, reads, tainted)
    inline(singles(assigns, reads, tainted))
  end

  def singles(assigns, reads, tainted)
    found = {}
    assigns.each do |name, nodes|
      next if tainted.include?(name)
      next unless nodes.size == 1
      next unless reads[name].size == 1
      next if hoisted?(reads[name].first, nodes.first)
      found[nodes.first] = reads[name].first
    end
    found
  end

  def inline(singles)
    movable = singles.select { |assign, _| solo?(assign) && !swallows?(assign, singles) }
    crossings = {}
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
      corrector.replace(read.source_range, inlined(assign.children.last, read))
      corrector.remove(range_by_whole_lines(assign.source_range, include_final_newline: true))
    end
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
    child = read
    parent = read.parent
    until parent.nil?
      return true unless before(parent, child, assign).all? do |node|
        deferred?(node, read, movable, crossings)
      end
      return false if parent.equal?(assign.parent)
      child = parent
      parent = parent.parent
    end
    false
  end

  def before(parent, child, assign)
    kids = parent.children
    stop = kids.index { |node| node.equal?(child) }
    return [] if stop.nil?
    return kids[0...stop] unless parent.equal?(assign.parent)
    kids[(kids.index { |node| node.equal?(assign) } + 1)...stop]
  end

  def deferred?(node, read, movable, crossings)
    return true if pure?(node)
    twin = movable[node]
    return false if twin.nil?
    return false if twin.source_range.begin_pos < read.source_range.begin_pos
    !crossed?(twin, node, movable, crossings)
  end

  def pure?(node)
    return true unless node.is_a?(RuboCop::AST::Node)
    return false unless PURE_TYPES.include?(node.type)
    node.each_child_node.all? { |kid| pure?(kid) }
  end
end
