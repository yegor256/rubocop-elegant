# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Forbids declaring a class inside a module declaration. Instead, the
# class must be declared with the compact namespace syntax, like
# +class Foo::Bar+. An empty module +module Foo; end+, a module that
# contains only other modules, methods, or constants, and a class
# nested inside another class are all allowed; only a class whose
# nearest enclosing scope is a module is rejected.
class RuboCop::Cop::Elegant::NoClassInModule < RuboCop::Cop::Base
  MSG = 'Class %<name>s must use compact namespace syntax, not be nested inside a module'
  public_constant :MSG

  def on_class(node)
    owner = node.each_ancestor(:module, :class).first
    return if owner.nil? || !owner.module_type?
    add_offense(node, message: format(MSG, name: label(node)))
  end

  private

  def label(node)
    node.children[0].source
  end
end
