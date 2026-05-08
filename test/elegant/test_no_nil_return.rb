# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/rubocop-elegant'
require_relative '../test__helper'

class NoNilReturnTest < Minitest::Test
  ALLOWED = {
    'integer_literal_tail' => 'def foo; 42; end',
    'string_literal_tail' => "def foo; 'bar'; end",
    'method_call_tail' => 'def foo; bar; end',
    'multi_statement_non_nil_tail' => "def foo\n  bar\n  baz\nend",
    'if_else_with_non_nil_branches' => 'def foo; if x; 1; else; 2; end; end',
    'case_with_else_non_nil_branches' => 'def foo; case x; when 1; 2; else; 3; end; end',
    'class_method_non_nil_tail' => 'def self.foo; 42; end',
    'empty_body_method' => "def foo\nend",
    'return_non_nil_inside_method' => "def foo\n  return 1 if x\n  2\nend",
    'outer_method_with_clean_inner_def' => "def foo\n  def bar; 7; end\n  42\nend",
    'nested_if_else_all_non_nil' => 'def foo; if x; if y; 1; else; 2; end; else; 3; end; end',
    'kwbegin_non_nil_tail' => "def foo\n  begin\n    bar\n    baz\n  end\nend",
    'bare_return_keyword' => "def foo\n  return if x\n  bar\nend",
    'if_without_else' => 'def foo; if x; 1; end; end',
    'unless_modifier' => 'def foo; bar unless x; end',
    'modifier_if' => 'def foo; bar if x; end',
    'case_without_else' => 'def foo; case x; when 1; 2; end; end',
    'if_branch_contains_nil' => 'def foo; if x; nil; else; 2; end; end',
    'case_else_is_nil' => 'def foo; case x; when 1; 2; else; nil; end; end'
  }.freeze
  public_constant :ALLOWED

  VIOLATIONS = {
    'literal_nil_as_tail' => ['def foo; nil; end', 1],
    'explicit_return_nil' => ['def foo; return nil; end', 1],
    'multi_statement_nil_tail' => ["def foo\n  bar\n  nil\nend", 1],
    'class_method_nil_tail' => ['def self.foo; nil; end', 1],
    'class_method_return_nil' => ['def self.foo; return nil; end', 1],
    'multiple_explicit_returns' =>
      ["def foo\n  return nil if x\n  return nil if y\n  bar\nend", 2],
    'return_nil_alongside_nil_tail' =>
      ["def foo\n  return nil if x\n  nil\nend", 2],
    'kwbegin_nil_tail' => ["def foo\n  begin\n    bar\n    nil\n  end\nend", 1]
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

  def test_attributes_offense_only_to_inner_nested_def
    source = "def foo\n  def bar\n    return nil\n  end\n  42\nend"
    total = offenses(source).size
    assert_equal(1, total, "Inner def with return nil should produce exactly 1 offense, got #{total}")
  end

  private

  def offenses(source)
    config = RuboCop::Config.new
    cop = RuboCop::Cop::Elegant::NoNilReturn.new(config)
    commissioner = RuboCop::Cop::Commissioner.new([cop], [], raise_error: true)
    processed = RuboCop::ProcessedSource.new(source, Float(RUBY_VERSION[/[0-9]+.[0-9]+/]))
    result = commissioner.investigate(processed)
    result.offenses
  end
end
