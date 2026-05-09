# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/rubocop-elegant'
require_relative '../test__helper'

class ClassInModuleTest < Minitest::Test
  ALLOWED = {
    'class_inside_single_module' => "module Foo\n  class Bar\n  end\nend",
    'class_inside_nested_modules' => "module Foo\n  module Baz\n    class Bar\n    end\n  end\nend",
    'compact_namespaced_class' => "class Foo::Bar\nend",
    'deeply_namespaced_compact_class' => "class Foo::Bar::Baz\nend",
    'module_without_any_class' => "module Foo\nend",
    'top_level_method_only' => "def foo\nend",
    'nested_class_inside_class_inside_module' => "module Foo\n  class Bar\n    class Baz\n    end\n  end\nend",
    'class_with_inheritance_inside_module' => "module Foo\n  class Bar < StandardError\n  end\nend"
  }.freeze
  public_constant :ALLOWED

  VIOLATIONS = {
    'plain_top_level_class' => ["class Foo\nend", 1],
    'top_level_class_with_explicit_root' => ["class ::Foo\nend", 1],
    'top_level_class_with_nested_class' => ["class Foo\n  class Bar\n  end\nend", 2],
    'two_top_level_classes' => ["class Foo\nend\nclass Bar\nend", 2],
    'top_level_class_with_inheritance' => ["class Foo < StandardError\nend", 1]
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
      [RuboCop::Cop::Elegant::ClassInModule.new(RuboCop::Config.new)], [], raise_error: true
    ).investigate(
      RuboCop::ProcessedSource.new(source, Float(RUBY_VERSION[/[0-9]+.[0-9]+/]))
    ).offenses
  end
end
