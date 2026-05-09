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
class RuboCop::Cop::Elegant::NoRedundantVariable < RuboCop::Cop::Base
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
    assigns.each do |name, nodes|
      next if tainted.include?(name)
      next unless nodes.size == 1
      next unless reads[name].size == 1
      next if hoisted?(reads[name].first, nodes.first)
      add_offense(nodes.first, message: format(MSG, name: name))
    end
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
end
