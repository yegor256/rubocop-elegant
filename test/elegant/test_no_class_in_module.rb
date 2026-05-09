# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/rubocop-elegant'
require_relative '../test__helper'

class NoClassInModuleTest < Minitest::Test
  ALLOWED = {
    'compact_namespaced_class' => "class Foo::Bar\nend",
    'deeply_namespaced_compact_class' => "class Foo::Bar::Baz\nend",
    'empty_module' => "module Foo\nend",
    'nested_empty_modules' => "module Foo\n  module Bar\n  end\nend",
    'module_with_method_only' => "module Foo\n  def baz\n  end\nend",
    'module_with_constant_only' => "module Foo\n  BAR = 1\nend",
    'module_with_method_and_constant' => "module Foo\n  BAR = 1\n  def baz\n  end\nend",
    'plain_top_level_class' => "class Foo\nend",
    'top_level_class_with_inheritance' => "class Foo < StandardError\nend",
    'nested_class_inside_class_top_level' => "class Foo\n  class Bar\n  end\nend",
    'top_level_method_only' => "def foo\nend"
  }.freeze
  public_constant :ALLOWED

  VIOLATIONS = {
    'class_inside_single_module' => ["module Foo\n  class Bar\n  end\nend", 1],
    'class_inside_nested_modules' => ["module Foo\n  module Baz\n    class Bar\n    end\n  end\nend", 1],
    'two_classes_inside_one_module' => ["module Foo\n  class Bar\n  end\n  class Baz\n  end\nend", 2],
    'class_with_inheritance_inside_module' => ["module Foo\n  class Bar < StandardError\n  end\nend", 1],
    'outer_class_only_when_nested_inside_class_inside_module' =>
      ["module Foo\n  class Bar\n    class Baz\n    end\n  end\nend", 1],
    'class_alongside_empty_submodule' => ["module Foo\n  module Bar\n  end\n  class Baz\n  end\nend", 1]
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
      [RuboCop::Cop::Elegant::NoClassInModule.new(RuboCop::Config.new)], [], raise_error: true
    ).investigate(
      RuboCop::ProcessedSource.new(source, Float(RUBY_VERSION[/[0-9]+.[0-9]+/]))
    ).offenses
  end
end
