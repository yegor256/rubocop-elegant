# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/rubocop-elegant'
require_relative '../test__helper'

class OneClassPerFileTest < Minitest::Test
  ALLOWED = {
    'empty_file' => '',
    'single_top_level_class' => "class Foo\n  def x\n  end\nend",
    'single_empty_class' => "class Foo\nend",
    'forward_declaration_then_nested_class' =>
      "class Foo::Bar\nend\nclass Foo::Bar::Baz < StandardError\nend",
    'two_empty_namespaces_then_real_class' =>
      "class Foo\nend\nclass Foo::Bar\nend\nclass Foo::Bar::Baz\n  def x\n  end\nend",
    'empty_error_subclass_after_forward_declaration' =>
      "class Foo::Bar\nend\nclass Foo::Bar::Boom < StandardError\nend",
    'top_level_method_only' => "def foo\nend",
    'require_then_forward_then_real_class' =>
      "require 'foo'\nclass Foo::Bar\nend\nclass Foo::Bar::Baz\n  def x\n  end\nend",
    'class_inside_module_does_not_count' =>
      "module Foo\n  class Bar\n    def x\n    end\n  end\n  class Baz\n    def y\n    end\n  end\nend"
  }.freeze
  public_constant :ALLOWED

  VIOLATIONS = {
    'two_non_empty_top_level_classes' =>
      ["class Foo\n  def x\n  end\nend\nclass Bar\n  def y\n  end\nend", 1],
    'three_non_empty_top_level_classes' =>
      ["class Foo\n  def x\n  end\nend\nclass Bar\n  def y\n  end\nend\nclass Baz\n  def z\n  end\nend", 2],
    'forward_declaration_then_two_real_classes' =>
      ["class Foo::Bar\nend\nclass Foo::Bar::Baz\n  def x\n  end\nend\nclass Foo::Bar::Qux\n  def y\n  end\nend", 1]
  }.freeze
  public_constant :VIOLATIONS

  ALLOWED.each do |name, source|
    define_method("test_allows_#{name}") do
      total = offenses(source).size
      assert_equal(0, total, "Expected no offense in #{name.tr('_', ' ')}, got #{total}")
    end
  end

  VIOLATIONS.each do |name, (source, count)|
    define_method("test_registers_offense_for_#{name}") do
      total = offenses(source).size
      assert_equal(count, total, "Expected #{count} offense(s) for #{name.tr('_', ' ')}, got #{total}")
    end
  end

  private

  def offenses(source)
    RuboCop::Cop::Commissioner.new(
      [RuboCop::Cop::Elegant::OneClassPerFile.new(RuboCop::Config.new)], [], raise_error: true
    ).investigate(
      RuboCop::ProcessedSource.new(source, Float(RUBY_VERSION[/[0-9]+.[0-9]+/]))
    ).offenses
  end
end
