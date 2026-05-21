# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Enforces one top-level class per file, treating empty class bodies as
# namespace scaffolding rather than real classes. An empty top-level
# +class Foo::Bar; end+ resolves a parent namespace so that the actual
# class in the same file can use the compact-namespaced form required
# by +Elegant/NoClassInModule+ without a circular require; it is not a
# class definition in its own right. Only when two or more top-level
# class bodies are non-empty does the cop register an offense, on every
# such class after the first.
class RuboCop::Cop::Elegant::OneClassPerFile < RuboCop::Cop::Base
  MSG = 'Only one non-empty class per file is allowed; %<name>s is the extra one'
  public_constant :MSG

  def on_new_investigation
    real = tops.reject { |node| node.body.nil? }
    real.drop(1).each do |node|
      add_offense(node, message: format(MSG, name: label(node)))
    end
  end

  private

  def tops
    ast = processed_source.ast
    return [] if ast.nil?
    return [ast] if ast.class_type?
    return [] unless ast.begin_type?
    ast.children.select(&:class_type?)
  end

  def label(node)
    node.children[0].source
  end
end
