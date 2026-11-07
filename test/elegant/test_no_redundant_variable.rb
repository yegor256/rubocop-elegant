# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/rubocop-elegant'
require_relative '../test__helper'
require 'timeout'

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
    'read_inside_ensure' => "def foo\n  x = compute\n  bar\nensure\n  baz(x)\nend",
    'call_between_assignment_and_read' => "def foo\n  line = receive\n  reader.close\n  bar(line)\nend",
    'mutation_between_assignment_and_read' => "def foo\n  touched = ledger.uniq\n  ledger.clear\n  touched\nend",
    'timed_call_between_assignment_and_read' => "def foo\n  started = monotonic\n  bar\n  monotonic - started\nend",
    'yield_read_after_other_work' => "def foo\n  returned = yield\n  log(out)\n  returned\nend",
    'calls_before_read_in_same_array' => "def foo\n  returned = yield\n  [out.string, err.string, returned]\nend",
    'call_before_read_in_same_argument_list' => "def foo\n  x = bar\n  baz(qux, x)\nend",
    'local_assignment_that_changes_saved_value' =>
      "def foo\n  state = :old\n  saved = state\n  state = :new\n  saved\nend",
    'constant_lookup_between_assignment_and_read' =>
      "def foo\n  saved = $state\n  Trigger::Value\n  saved\nend",
    'instance_variable_operand_before_read' => "def foo\n  x = bump\n  bar(@n, x)\nend",
    'global_variable_operand_before_read' => "def foo\n  x = bump\n  bar($n, x)\nend",
    'class_variable_operand_before_read' => "def foo\n  x = bump\n  bar(@@n, x)\nend",
    'constant_operand_before_read' => "def foo\n  x = bump\n  bar(CONST, x)\nend",
    'back_reference_operand_before_read' => "def foo\n  x = (s =~ /a/)\n  bar($~, x)\nend",
    'instance_variable_inside_array_before_read' => "def foo\n  x = bump\n  bar([@n], x)\nend",
    'chained_assignments_read_in_separate_statements' =>
      "def foo\n  a = one\n  b = two\n  bar(a)\n  baz(b)\nend",
    'local_assigned_by_rhs_read_before_read' => "def foo(y)\n  x = (y = 2)\n  bar(y, x)\nend",
    'local_assigned_by_rhs_read_in_gap' => "def foo(y)\n  x = (y = 2)\n  [y]\n  bar(x)\nend",
    'local_compound_assigned_by_rhs_read_before_read' => "def foo(y)\n  x = (y += 1)\n  bar(y, x)\nend",
    'local_multiple_assigned_by_rhs_read_before_read' => "def foo(y)\n  x = (y, z = 1, 2)\n  bar(y, x, z)\nend",
    'local_assigned_in_rhs_block_read_before_read' => "def foo(y)\n  x = tap { y = 3 }\n  bar(y, x)\nend",
    'local_captured_by_rhs_regexp_read_before_read' =>
      "def foo(y)\n  x = (/(?<y>\\d)/ =~ s)\n  bar(y, x)\nend",
    'local_captured_by_rhs_quoted_group_read_before_read' =>
      "def foo(y)\n  x = (/(?'y'\\d)/e =~ s)\n  bar(y, x)\nend",
    'local_bound_by_rhs_pattern_read_before_read' => "def foo(y)\n  x = (s in [y])\n  bar(y, x)\nend",
    'local_assigned_by_closure_rhs_may_call' =>
      "def foo(y)\n  inc = -> { y += 1 }\n  inc.call\n  x = inc.call\n  bar(y, x)\nend",
    'method_calling_binding' => "def foo(y)\n  x = mutate(binding)\n  bar(y, x)\nend",
    'method_calling_eval' => "def foo(y)\n  x = eval('y = 2')\n  bar(y, x)\nend",
    'method_calling_eval_on_kernel' => "def foo(y)\n  x = Kernel.eval('y = 2')\n  bar(y, x)\nend",
    'method_evaluating_a_string_on_self' => "def foo(y)\n  x = instance_eval('y = 2')\n  bar(y, x)\nend",
    'method_sending_eval' => "def foo(y)\n  x = send(:eval, 'y = 2')\n  bar(y, x)\nend",
    'method_calling_binding_of_a_proc' =>
      "def foo(y)\n  pr = proc {}\n  pr.call\n  x = pr.binding.local_variable_set(:y, 2)\n  bar(y, x)\nend",
    'local_interpolated_before_read' => "def foo(y)\n  x = bar\n  baz(\"\#{y}\#{x}\")\nend",
    'local_interpolated_into_regexp_between_assignment_and_read' =>
      "def foo(y)\n  x = bar\n  /\#{y}/\n  baz(x)\nend",
    'range_of_locals_between_assignment_and_read' => "def foo(a, b)\n  x = bar\n  [a..b]\n  baz(x)\nend",
    'hash_keyed_by_local_between_assignment_and_read' =>
      "def foo(y)\n  x = bar\n  [{ y => 1 }]\n  baz(x)\nend",
    'read_before_reassignment_of_parameter' => "def foo(y)\n  x = bar(y)\n  y = 1\n  x\nend",
    'read_inside_own_heredoc' => "def foo(name)\n  name = <<~TXT\n    Hello \#{name}\n  TXT\nend",
    'embedded_reassignment_identical_to_the_assignment' => "def foo\n  x = bar\n  qux(x = bar, x)\nend",
    'read_before_reassignment_of_block_argument' => "def foo\n  [1].each do |y|\n    bar(y)\n    y = 2\n  end\nend",
    'read_inside_assignment_to_local_named_like_rhs_call' => "def foo\n  old = name\n  name = old.upcase\nend",
    'read_inside_assignment_to_local_assigned_in_rhs_block' =>
      "def foo\n  x = bar(tap { d = 1 })\n  d = [x]\nend",
    'read_inside_assignment_to_it_when_rhs_block_uses_it' =>
      "def foo\n  x = items.map { it * 2 }\n  it = [x]\nend"
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
      ["def foo\n  x = bar\n  case x\n  when 1\n    one\n  end\nend", 1],
    'pure_statement_between_assignment_and_read' =>
      ["def foo\n  x = bar\n  1\n  baz(x)\nend", 1],
    'rational_literal_between_assignment_and_read' =>
      ["def foo\n  x = bar\n  1r\n  baz(x)\nend", 1],
    'complex_literal_between_assignment_and_read' =>
      ["def foo\n  x = bar\n  1i\n  baz(x)\nend", 1],
    'inclusive_range_between_assignment_and_read' =>
      ["def foo\n  x = bar\n  1..2\n  baz(x)\nend", 1],
    'exclusive_range_between_assignment_and_read' =>
      ["def foo\n  x = bar\n  1...2\n  baz(x)\nend", 1],
    'pure_operands_before_read' =>
      ["def foo\n  x = bar\n  baz(1, [2], x)\nend", 1],
    'self_operand_before_read' =>
      ["def foo\n  x = bar\n  baz(self, x)\nend", 1],
    'local_operand_before_read' =>
      ["def foo(y)\n  x = bar\n  baz(y, x)\nend", 1],
    'read_inside_another_redundant_assignment' =>
      ["def foo\n  a = one\n  b = [a]\n  bar(b)\nend", 2],
    'call_after_read_in_same_argument_list' =>
      ["def foo\n  x = bar\n  baz(x, qux)\nend", 1],
    'chained_assignments_read_out_of_order' =>
      ["def foo\n  a = one\n  b = two\n  bar(b, a)\nend", 1],
    'local_operand_before_read_when_rhs_assigns_another_local' =>
      ["def foo(y)\n  x = (z = 2)\n  bar(y, x, z)\nend", 1],
    'local_operand_before_read_when_rhs_captures_another_local' =>
      ["def foo(y)\n  x = (/(?<z>\\d)(?<=a)/ =~ s)\n  bar(y, x, z)\nend", 1],
    'local_operand_assigned_only_outside_closures' =>
      ["def foo(y)\n  [1].each { |i| sum(i) }\n  x = compute\n  bar(y, x)\nend", 1],
    'pure_rhs_crossing_local_assigned_in_closure' =>
      ["def foo\n  total = 0\n  [1].each { |i| total += i }\n  label = 'Total'\n  report(total, label)\nend", 1],
    'hash_keyed_by_local_around_read' =>
      ["def foo(key)\n  val = compute\n  store({ key => val })\nend", 1],
    'range_bounded_by_local_around_read' =>
      ["def foo(low)\n  high = compute\n  bar(low..high)\nend", 1],
    'literal_text_before_read_in_interpolation' =>
      ["def foo\n  x = bar\n  baz(\"a\#{x}\")\nend", 1],
    'read_inside_assignment_to_unrelated_local' =>
      ["def foo\n  old = name\n  other = old.upcase\n  other\nend", 2],
    'method_evaluating_a_block_on_self' =>
      ["def foo(y)\n  x = compute\n  bar(y, x)\n  instance_eval { baz }\nend", 1],
    'read_inside_reassignment_of_local_read_by_rhs' =>
      ["def foo(path)\n  clean = path.strip\n  path = clean.downcase\n  path\nend", 1]
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
    'call_between_assignment_and_read_is_left_alone' => [
      "def foo\n  line = receive\n  reader.close\n  bar(line)\nend",
      "def foo\n  line = receive\n  reader.close\n  bar(line)\nend"
    ],
    'calls_before_read_in_array_are_left_alone' => [
      "def foo\n  returned = yield\n  [out.string, returned]\nend",
      "def foo\n  returned = yield\n  [out.string, returned]\nend"
    ],
    'read_inside_another_redundant_assignment_inlines_the_inner_one' => [
      "def foo\n  a = one\n  b = [a]\n  bar(b)\nend",
      "def foo\n  b = [one]\n  bar(b)\nend"
    ],
    'instance_variable_operand_before_read_is_left_alone' => [
      "def foo\n  x = bump\n  bar(@n, x)\nend",
      "def foo\n  x = bump\n  bar(@n, x)\nend"
    ],
    'local_assigned_by_rhs_read_before_read_is_left_alone' => [
      "def foo(y)\n  x = (y = 2)\n  bar(y, x)\nend",
      "def foo(y)\n  x = (y = 2)\n  bar(y, x)\nend"
    ],
    'local_assigned_by_rhs_read_after_read_is_inlined' => [
      "def foo(y)\n  x = (y = 2)\n  bar(x, y)\nend",
      "def foo(y)\n  bar((y = 2), y)\nend"
    ],
    'read_inside_assignment_to_local_named_like_rhs_call_is_left_alone' => [
      "def foo\n  old = name\n  name = old.upcase\nend",
      "def foo\n  old = name\n  name = old.upcase\nend"
    ],
    'assignment_holding_the_read_of_a_crossed_variable_is_inlined' => [
      "def foo\n  a = one\n  b = [qux, a]\n  bar(b)\nend",
      "def foo\n  a = one\n  bar([qux, a])\nend"
    ],
    'assignment_holding_the_read_of_an_uncorrectable_variable_is_inlined' => [
      "def foo\n  a = one # note\n  b = [a]\n  bar(b)\nend",
      "def foo\n  a = one # note\n  bar([a])\nend"
    ],
    'hash_keyed_by_local_around_read_is_inlined' => [
      "def foo(key)\n  val = compute\n  store({ key => val })\nend",
      "def foo(key)\n  store({ key => compute })\nend"
    ],
    'hash_into_bare_send_arg_is_wrapped' =>
      ["def foo\n  x = { a: 1 }\n  baz x\nend", "def foo\n  baz ({ a: 1 })\nend"],
    'shorthand_pair_expands_to_long_form' =>
      ["def foo\n  ids = compute\n  bar(ids:)\nend", "def foo\n  bar(ids: compute)\nend"],
    'shorthand_pair_in_hash_literal_expands' =>
      ["def foo\n  ids = compute\n  bar({ ids: })\nend", "def foo\n  bar({ ids: compute })\nend"],
    'long_form_pair_still_inlines_the_value_only' =>
      ["def foo\n  ids = compute\n  bar(list: ids)\nend", "def foo\n  bar(list: compute)\nend"]
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

  def test_keeps_arguments_when_rhs_assigns_one
    source = "def foo(y)\n  x = (y = 2)\n  bar(y, x)\nend"
    fixed = autocorrect(source)
    assert_equal(arguments(source), arguments(fixed), "Auto-correct changed what bar receives, got #{fixed.inspect}")
  end

  def test_keeps_order_when_twin_is_disabled
    source = [
      'def foo', '  a = one', '  # rubocop:disable Elegant/NoRedundantVariable', '  b = two',
      '  # rubocop:enable Elegant/NoRedundantVariable', '  bar(a, b)', 'end'
    ].join("\n")
    fixed = autocorrect(source, directives: true)
    assert_equal(source, fixed, "Expected the assignment before a disabled one to stay, got #{fixed.inspect}")
  end

  def test_scales_to_a_long_chain_of_assignments
    assignments = (1..20).map { |idx| "  a#{idx} = f#{idx}" }
    arguments = (1..20).map { |idx| "a#{idx}" }.join(', ')
    source = ['def foo', *assignments, "  sink(#{arguments})", 'end'].join("\n")
    total = Timeout.timeout(2) { offenses(source).size }
    assert_equal(20, total, "Expected all 20 assignments to be flagged, got #{total}")
  end

  private

  def offenses(source)
    RuboCop::Cop::Commissioner.new(
      [RuboCop::Cop::Elegant::NoRedundantVariable.new(RuboCop::Config.new)], [], raise_error: true
    ).investigate(
      RuboCop::ProcessedSource.new(source, Float(RUBY_VERSION[/[0-9]+.[0-9]+/]))
    ).offenses
  end

  def arguments(source)
    host = Class.new { define_method(:bar) { |*args| args } }
    host.class_eval(source, __FILE__, __LINE__)
    host.new.foo(1)
  end

  def autocorrect(source, directives: false)
    processed = RuboCop::ProcessedSource.new(source, Float(RUBY_VERSION[/[0-9]+.[0-9]+/]))
    if directives
      processed.config = RuboCop::ConfigLoader.default_configuration
      processed.registry = RuboCop::Cop::Registry.global
    end
    found = RuboCop::Cop::Commissioner.new(
      [RuboCop::Cop::Elegant::NoRedundantVariable.new(RuboCop::Config.new)], [], raise_error: true
    ).investigate(processed).offenses
    corrector = RuboCop::Cop::Corrector.new(processed)
    found.each { |o| corrector.merge!(o.corrector) unless o.corrector.nil? }
    corrector.process
  end
end
