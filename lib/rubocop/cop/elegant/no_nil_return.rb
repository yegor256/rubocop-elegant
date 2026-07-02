# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Forbids returning the literal +nil+ explicitly. The cop flags two
# patterns: a +return nil+ statement anywhere inside the body, and a
# body whose tail expression is the literal +nil+ (whether it stands
# alone or appears as the last statement of a multi-statement body).
# Both patterns are checked inside method definitions and inside
# blocks, lambdas, and procs. Bodies that omit +return+, use a bare
# +return+ keyword, or merely happen to evaluate to +nil+ through
# control flow are not flagged.
class RuboCop::Cop::Elegant::NoNilReturn < RuboCop::Cop::Base
  MSG = 'Method must not return nil explicitly'
  public_constant :MSG

  SCOPES = %i[def defs block numblock].freeze
  private_constant :SCOPES

  def on_def(node)
    check(node)
  end

  def on_defs(node)
    check(node)
  end

  def on_block(node)
    check(node)
  end

  def on_numblock(node)
    check(node)
  end

  private

  def check(node)
    return if node.body.nil?
    explicit(node)
    tail(node.body)
  end

  def explicit(node)
    node.each_descendant(:return) do |ret|
      next unless ret.each_ancestor(*SCOPES).first.equal?(node)
      add_offense(ret) if void?(ret)
    end
  end

  def void?(ret)
    return false if ret.children.empty?
    ret.children.all?(&:nil_type?)
  end

  def tail(node)
    return add_offense(node) if node.nil_type?
    tail(node.children.last) if node.begin_type? || node.kwbegin_type?
  end
end
