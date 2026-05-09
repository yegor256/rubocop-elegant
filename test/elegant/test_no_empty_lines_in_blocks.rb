# frozen_string_literal: true

require_relative '../../lib/rubocop-elegant'
# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'

class NoEmptyLinesInBlocksTest < Minitest::Test
  def test_registers_offense_for_empty_line_in_do
    assert_equal(
      1, offenses("loop do\n  x = 1\n\n  x\nend").size,
      'Expected offense not registered for empty line in do/end block'
    )
  end

  def test_registers_offense_for_empty_line_in_brace
    assert_equal(
      1, offenses("[1].each { |x|\n  y = x\n\n  y\n}").size,
      'Expected offense not registered for empty line in brace block'
    )
  end

  def test_registers_offense_for_empty_line_in_if
    assert_equal(
      1, offenses("if true\n  x = 1\n\n  x\nend").size,
      'Expected offense not registered for empty line in if/end'
    )
  end

  def test_registers_offense_for_empty_line_in_unless
    assert_equal(
      1, offenses("unless false\n  x = 1\n\n  x\nend").size,
      'Expected offense not registered for empty line in unless/end'
    )
  end

  def test_registers_offense_for_empty_line_in_while
    assert_equal(
      1, offenses("while true\n  x = 1\n\n  break\nend").size,
      'Expected offense not registered for empty line in while/end'
    )
  end

  def test_registers_offense_for_empty_line_in_until
    assert_equal(
      1, offenses("until false\n  x = 1\n\n  break\nend").size,
      'Expected offense not registered for empty line in until/end'
    )
  end

  def test_registers_offense_for_empty_line_in_for
    assert_equal(
      1, offenses("for i in [1]\n  x = i\n\n  x\nend").size,
      'Expected offense not registered for empty line in for/end'
    )
  end

  def test_registers_offense_for_empty_line_in_case
    assert_equal(
      1, offenses("case 1\nwhen 1\n\n  :one\nend").size,
      'Expected offense not registered for empty line in case/end'
    )
  end

  def test_registers_offense_for_empty_line_in_case_in
    assert_equal(
      1, offenses("case 1\nin 1\n\n  :one\nend").size,
      'Expected offense not registered for empty line in case/in pattern'
    )
  end

  def test_registers_offense_for_empty_line_in_begin
    assert_equal(
      1, offenses("begin\n  x = 1\n\n  x\nend").size,
      'Expected offense not registered for empty line in begin/end'
    )
  end

  def test_registers_offense_for_empty_line_in_num
    assert_equal(
      1, offenses("[1].each do\n  puts _1\n\n  puts _1\nend").size,
      'Expected offense not registered for empty line in numbered block'
    )
  end

  def test_registers_offense_for_multiple_empty_lines
    assert_equal(
      2, offenses("loop do\n  x = 1\n\n\n  x\nend").size,
      'Expected offenses not registered for multiple empty lines in block'
    )
  end

  def test_allows_block_without_empty_lines
    assert_equal(0, offenses("loop do\n  x = 1\n  x\nend").size, 'Block without empty lines should be allowed')
  end

  def test_allows_single_line_block
    assert_equal(0, offenses('[1].each { |x| x + 1 }').size, 'Single line block should be allowed')
  end

  def test_allows_empty_block
    assert_equal(0, offenses("loop do\nend").size, 'Empty block should be allowed')
  end

  def test_allows_top_level_empty_lines
    assert_equal(0, offenses("x = 1\n\ny = 2").size, 'Top level empty lines should not be flagged')
  end

  def test_allows_empty_lines_between_methods
    assert_equal(
      0,
      offenses("class Foo\n  def a\n    1\n  end\n\n  def b\n    2\n  end\nend").size,
      'Empty line between class methods should not be flagged'
    )
  end

  def test_allows_empty_lines_between_defs_in_do_block
    assert_equal(
      0,
      offenses("refine Foo do\n  def a\n    1\n  end\n\n  def b\n    2\n  end\nend").size,
      'Empty line between sibling defs inside a do/end block should not be flagged'
    )
  end

  def test_allows_empty_lines_between_defs_in_begin
    assert_equal(
      0,
      offenses("begin\n  def a\n    1\n  end\n\n  def b\n    2\n  end\nend").size,
      'Empty line between sibling defs inside a begin/end block should not be flagged'
    )
  end

  def test_allows_empty_lines_in_nested_class
    assert_equal(
      0,
      offenses("describe do\n  class Foo\n    def a\n      1\n    end\n\n    def b\n      2\n    end\n  end\nend").size,
      'Empty line between sibling defs inside a class inside a block should not be flagged'
    )
  end

  def test_deduplicates_nested_blocks
    assert_equal(
      1, offenses("loop do\n  if true\n\n    x = 1\n  end\nend").size,
      'Same empty line in nested blocks should be reported once'
    )
  end

  def test_corrects_empty_line_in_block
    assert_equal(
      "loop do\n  x = 1\n  x\nend",
      correct("loop do\n  x = 1\n\n  x\nend"),
      'Empty line in block not removed'
    )
  end

  def test_corrects_multiple_empty_lines
    assert_equal(
      "loop do\n  x = 1\n  x\nend",
      correct("loop do\n  x = 1\n\n\n  x\nend"),
      'Multiple empty lines in block not removed'
    )
  end

  private

  def offenses(source)
    RuboCop::Cop::Commissioner.new(
      [RuboCop::Cop::Elegant::NoEmptyLinesInBlocks.new(RuboCop::Config.new)], [], raise_error: true
    ).investigate(
      RuboCop::ProcessedSource.new(source, Float(RUBY_VERSION[/[0-9]+.[0-9]+/]))
    ).offenses
  end

  def correct(source)
    processed = RuboCop::ProcessedSource.new(source, Float(RUBY_VERSION[/[0-9]+.[0-9]+/]))
    corrector = RuboCop::Cop::Corrector.new(processed.buffer)
    RuboCop::Cop::Commissioner.new(
      [RuboCop::Cop::Elegant::NoEmptyLinesInBlocks.new(RuboCop::Config.new, autocorrect: true)], [], raise_error: true
    ).investigate(processed).correctors.compact.each { |c| corrector.merge!(c) }
    corrector.rewrite
  end
end
