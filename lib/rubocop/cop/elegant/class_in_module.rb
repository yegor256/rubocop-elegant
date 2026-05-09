# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Enforces that every class be defined inside a module. A class declared
# at the top level, or nested only inside another class, pollutes the
# global namespace and breaks modular design. The compact namespaced
# form +class Foo::Bar+ is allowed because its name already resolves
# into an enclosing namespace.
class RuboCop::Cop::Elegant::ClassInModule < RuboCop::Cop::Base
  MSG = 'Class %<name>s must be defined inside a module, not globally'
  public_constant :MSG

  def on_class(node)
    return if namespaced?(node)
    return if scoped?(node)
    add_offense(node, message: format(MSG, name: label(node)))
  end

  private

  def namespaced?(node)
    scope = node.children[0].children[0]
    !scope.nil? && scope.type != :cbase
  end

  def scoped?(node)
    node.each_ancestor(:module).any?
  end

  def label(node)
    node.children[0].source
  end
end
