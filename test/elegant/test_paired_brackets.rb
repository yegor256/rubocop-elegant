# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/rubocop-elegant'
require_relative '../test__helper'

class PairedBracketsTest < Minitest::Test
  ALLOWED = {
    'paired_parens_on_same_line' => 'foo(1, 2)',
    'paired_square_brackets_on_same_line' => '[1, 2, 3]',
    'paired_curly_braces_on_same_line' => '{ a: 1, b: 2 }',
    'opener_at_end_of_line_and_closer_at_start' => "foo(\n  1\n)",
    'split_square_brackets_at_line_edges' => "[\n  1,\n  2\n]",
    'split_curly_braces_at_line_edges' => "{\n  a: 1\n}",
    'block_brace_paired_on_same_line' => '[1].each { |x| x }',
    'trailing_comment_after_opener' => "foo( # explain\n  1\n)",
    'trailing_chain_after_closer' => "foo(\n  1\n).bar",
    'brackets_in_string_literal' => 'puts "(hello)"',
    'brackets_in_string_interpolation' => %(puts "value=\#{x}"),
    'brackets_in_percent_words_array' => '%w[a b c]',
    'brackets_in_percent_symbols_array' => '%i(a b c)',
    'brackets_in_comments' => "# (a)\nfoo",
    'indexer_brackets' => 'arr[0]',
    'empty_parens_paired' => 'foo()',
    'empty_parens_split_at_edges' => "foo(\n)",
    'nested_pairs_at_line_edges' => "foo(\n  bar(\n    1\n  )\n)"
  }.freeze
  public_constant :ALLOWED

  VIOLATIONS = {
    'opener_in_middle_of_line' => ["foo(bar(\n  1\n))", 2],
    'closer_not_at_start_of_line' => ["foo(\n  1)", 1],
    'opener_not_at_end_of_line' => ["foo(1,\n  2\n)", 1],
    'split_square_brackets_in_middle' => ["[1,\n 2]", 2],
    'block_brace_with_argument_split' => ["[1].each { |x|\n  x\n}", 1],
    'closer_not_at_start_when_chained_in_middle' => ["foo(\n  1).bar", 1]
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
    config = RuboCop::Config.new
    cop = RuboCop::Cop::Elegant::PairedBrackets.new(config)
    commissioner = RuboCop::Cop::Commissioner.new([cop], [], raise_error: true)
    processed = RuboCop::ProcessedSource.new(source, Float(RUBY_VERSION[/[0-9]+.[0-9]+/]))
    result = commissioner.investigate(processed)
    result.offenses
  end
end
