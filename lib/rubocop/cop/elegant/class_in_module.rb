# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Enforces that every class be defined inside a module. A class declared
# at the top level pollutes the global namespace and breaks modular
# design. The compact namespaced form +class Foo::Bar+ is allowed
# because its name already resolves into an enclosing namespace, and so
# is a class nested inside another class, since the enclosing class
# names it too: +class Foo::Bar; class Baz+ defines +Foo::Bar::Baz+.
# A class declared with an explicit root scope, +class ::Baz+, is global
# whatever encloses it lexically, so it is reported wherever it sits.
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
    scope = outer(node)
    !scope.nil? && scope.type != :cbase
  end

  def scoped?(node)
    return false unless outer(node).nil?
    node.each_ancestor(:module, :class).any?
  end

  def outer(node)
    node.children[0].children[0]
  end

  def label(node)
    node.children[0].source
  end
end
