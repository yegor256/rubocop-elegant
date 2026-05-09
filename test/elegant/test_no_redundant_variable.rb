# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/rubocop-elegant'
require_relative '../test__helper'

class NoRedundantVariableTest < Minitest::Test
  ALLOWED = {
    'variable_used_twice' => "def foo\n  x = bar\n  baz(x)\n  qux(x)\nend",
    'variable_reassigned_then_read' => "def foo\n  x = 1\n  x = 2\n  baz(x)\nend",
    'compound_plus_assignment' => "def foo\n  x = 0\n  arr.each { |e| x += e }\n  x\nend",
    'or_assign_modification' => "def foo\n  x = nil\n  x ||= compute\n  bar(x)\nend",
    'method_argument_used_once' => 'def foo(x); bar(x); end',
    'block_argument_used_once' => "def foo\n  arr.each { |e| bar(e) }\nend",
    'assignment_in_if_condition' => "def foo\n  if (x = bar)\n    baz(x)\n  end\nend",
    'assignment_in_while_condition' => "def foo\n  while (line = readline)\n    puts(line)\n  end\nend",
    'multiple_assignment' => "def foo\n  a, b = pair\n  a + b\nend",
    'rescue_exception_variable' => "def foo\n  bar\nrescue => e\n  log(e)\nend",
    'for_loop_iterator' => "def foo\n  for x in arr\n    bar(x)\n  end\nend",
    'variable_assigned_never_read' => "def foo\n  x = expensive\n  bar\nend",
    'class_method_two_reads' => "def self.foo\n  x = bar\n  baz(x)\n  qux(x)\nend",
    'no_local_variables' => "def foo\n  bar\n  baz\nend",
    'empty_body' => "def foo\nend",
    'variable_modified_via_send' => "def foo\n  x = []\n  x << 1\n  x\nend",
    'read_inside_block_loop' => "def foo\n  x = compute\n  arr.each { |e| bar(x, e) }\nend",
    'read_inside_while_loop' => "def foo\n  x = compute\n  while cond\n    bar(x)\n  end\nend",
    'read_inside_until_loop' => "def foo\n  x = compute\n  until cond\n    bar(x)\n  end\nend",
    'read_inside_for_loop' => "def foo\n  x = compute\n  for e in arr\n    bar(x, e)\n  end\nend",
    'read_inside_nested_block' => "def foo\n  x = compute\n  arr.each { |a| a.each { |b| bar(x, b) } }\nend"
  }.freeze
  public_constant :ALLOWED

  VIOLATIONS = {
    'simple_inlinable' => ["def foo\n  x = bar\n  baz(x)\nend", 1],
    'class_method_inlinable' => ["def self.foo\n  x = bar\n  baz(x)\nend", 1],
    'inlinable_inside_block' =>
      ["def foo\n  arr.each do |e|\n    y = e.bar\n    baz(y)\n  end\nend", 1],
    'multiple_redundant_in_one_method' =>
      ["def foo\n  a = one\n  b = two\n  bar(a, b)\nend", 2],
    'inlinable_with_rescue' =>
      ["def foo\n  x = bar\n  baz(x)\nrescue StandardError\n  retry\nend", 1],
    'each_def_has_own_redundant' =>
      ["def foo\n  x = bar\n  baz(x)\nend\ndef qux\n  y = bar\n  baz(y)\nend", 2],
    'inlinable_returned_directly' => ["def foo\n  x = compute\n  x\nend", 1],
    'inlinable_inside_if_branch' =>
      ["def foo\n  if cond\n    x = bar\n    baz(x)\n  end\nend", 1]
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

  def test_message_names_the_redundant_variable
    offense = offenses("def foo\n  greeting = 'hi'\n  puts(greeting)\nend").first
    assert_match(/"greeting"/, offense.message, "Expected message to quote the variable name, got #{offense.message}")
  end

  def test_inner_def_does_not_pollute_outer_scope
    total = offenses("def foo\n  x = 1\n  def bar\n    x = 2\n    baz(x)\n  end\n  qux(x)\n  zap(x)\nend").size
    assert_equal(1, total, "Expected only the inner def's redundant variable to be flagged, got #{total}")
  end

  private

  def offenses(source)
    RuboCop::Cop::Commissioner.new(
      [RuboCop::Cop::Elegant::NoRedundantVariable.new(RuboCop::Config.new)], [], raise_error: true
    ).investigate(
      RuboCop::ProcessedSource.new(source, Float(RUBY_VERSION[/[0-9]+.[0-9]+/]))
    ).offenses
  end
end
