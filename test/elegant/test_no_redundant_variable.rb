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
    'read_inside_nested_block' => "def foo\n  x = compute\n  arr.each { |a| a.each { |b| bar(x, b) } }\nend",
    'assigned_in_block_read_outside' => "def foo\n  x = nil\n  arr.each { |e| x = e }\n  bar(x)\nend",
    'read_inside_if_branch' => "def foo\n  x = compute\n  bar(x) if cond\nend",
    'read_inside_full_if_then_branch' => "def foo\n  x = compute\n  if cond\n    bar(x)\n  end\nend",
    'read_inside_if_else_branch' => "def foo\n  x = compute\n  if cond\n    bar\n  else\n    bar(x)\n  end\nend",
    'read_inside_case_when_branch' => "def foo\n  x = compute\n  case y\n  when 1\n    bar(x)\n  end\nend",
    'read_inside_case_match_in_branch' => "def foo\n  x = compute\n  case y\n  in 1\n    bar(x)\n  end\nend",
    'read_inside_and_rhs' => "def foo\n  x = compute\n  cond && bar(x)\nend",
    'read_inside_or_rhs' => "def foo\n  x = compute\n  cond || bar(x)\nend",
    'read_inside_rescue_body' => "def foo\n  x = compute\n  bar\nrescue\n  baz(x)\nend",
    'read_inside_ensure' => "def foo\n  x = compute\n  bar\nensure\n  baz(x)\nend"
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
      ["def foo\n  if cond\n    x = bar\n    baz(x)\n  end\nend", 1],
    'read_in_if_condition_position' =>
      ["def foo\n  x = bar\n  baz if x.empty?\nend", 1],
    'read_in_and_lhs_position' =>
      ["def foo\n  x = bar\n  baz(x) && qux\nend", 1],
    'read_in_case_subject_position' =>
      ["def foo\n  x = bar\n  case x\n  when 1\n    one\n  end\nend", 1]
  }.freeze
  public_constant :VIOLATIONS

  AUTOCORRECTIONS = {
    'send_call_inlines_unwrapped' =>
      ["def foo\n  x = bar\n  baz(x)\nend", "def foo\n  baz(bar)\nend"],
    'integer_literal_inlines_unwrapped' =>
      ["def foo\n  x = 42\n  baz(x)\nend", "def foo\n  baz(42)\nend"],
    'returned_directly_inlines' =>
      ["def foo\n  x = compute\n  x\nend", "def foo\n  compute\nend"],
    'binary_operator_wrapped_in_parens' =>
      ["def foo\n  x = a + b\n  baz(x)\nend", "def foo\n  baz((a + b))\nend"],
    'ternary_wrapped_in_parens' =>
      ["def foo\n  x = cond ? a : b\n  baz(x)\nend", "def foo\n  baz((cond ? a : b))\nend"],
    'hash_literal_with_braces_inlines_unwrapped' =>
      ["def foo\n  x = { a: 1 }\n  baz(x)\nend", "def foo\n  baz({ a: 1 })\nend"],
    'method_with_receiver_no_args_inlines_unwrapped' =>
      ["def foo\n  x = a.b\n  baz(x)\nend", "def foo\n  baz(a.b)\nend"],
    'inside_block_inlines' => [
      "def foo\n  arr.each do |e|\n    y = e.bar\n    baz(y)\n  end\nend",
      "def foo\n  arr.each do |e|\n    baz(e.bar)\n  end\nend"
    ],
    'multiple_redundant_inline_together' =>
      ["def foo\n  a = one\n  b = two\n  bar(a, b)\nend", "def foo\n  bar(one, two)\nend"],
    'class_method_inlines' =>
      ["def self.foo\n  x = bar\n  baz(x)\nend", "def self.foo\n  baz(bar)\nend"],
    'shared_line_assignment_is_left_alone' =>
      ["def foo\n  x = bar; baz(x)\nend", "def foo\n  x = bar; baz(x)\nend"],
    'hash_into_bare_send_arg_is_wrapped' =>
      ["def foo\n  x = { a: 1 }\n  baz x\nend", "def foo\n  baz ({ a: 1 })\nend"]
  }.freeze
  public_constant :AUTOCORRECTIONS

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

  AUTOCORRECTIONS.each do |name, (source, expected)|
    define_method("test_auto_corrects_#{name}") do
      fixed = autocorrect(source)
      msg = "Auto-correct on #{name.tr('_', ' ')} did not produce #{expected.inspect}, got #{fixed.inspect}"
      assert_equal(expected, fixed, msg)
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

  def autocorrect(source)
    processed = RuboCop::ProcessedSource.new(source, Float(RUBY_VERSION[/[0-9]+.[0-9]+/]))
    found = RuboCop::Cop::Commissioner.new(
      [RuboCop::Cop::Elegant::NoRedundantVariable.new(RuboCop::Config.new)], [], raise_error: true
    ).investigate(processed).offenses
    corrector = RuboCop::Cop::Corrector.new(processed)
    found.each { |o| corrector.merge!(o.corrector) unless o.corrector.nil? }
    corrector.process
  end
end
