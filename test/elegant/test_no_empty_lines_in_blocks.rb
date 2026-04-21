# frozen_string_literal: true

require_relative '../../lib/rubocop-elegant'
# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'

class NoEmptyLinesInBlocksTest < Minitest::Test
  def test_registers_offense_for_empty_line_in_do_block
    source = "loop do\n  x = 1\n\n  x\nend"
    offenses = offenses(source)
    assert_equal(1, offenses.size, 'Expected offense not registered for empty line in do/end block')
  end

  def test_registers_offense_for_empty_line_in_brace_block
    source = "[1].each { |x|\n  y = x\n\n  y\n}"
    offenses = offenses(source)
    assert_equal(1, offenses.size, 'Expected offense not registered for empty line in brace block')
  end

  def test_registers_offense_for_empty_line_in_if
    source = "if true\n  x = 1\n\n  x\nend"
    offenses = offenses(source)
    assert_equal(1, offenses.size, 'Expected offense not registered for empty line in if/end')
  end

  def test_registers_offense_for_empty_line_in_unless
    source = "unless false\n  x = 1\n\n  x\nend"
    offenses = offenses(source)
    assert_equal(1, offenses.size, 'Expected offense not registered for empty line in unless/end')
  end

  def test_registers_offense_for_empty_line_in_while
    source = "while true\n  x = 1\n\n  break\nend"
    offenses = offenses(source)
    assert_equal(1, offenses.size, 'Expected offense not registered for empty line in while/end')
  end

  def test_registers_offense_for_empty_line_in_until
    source = "until false\n  x = 1\n\n  break\nend"
    offenses = offenses(source)
    assert_equal(1, offenses.size, 'Expected offense not registered for empty line in until/end')
  end

  def test_registers_offense_for_empty_line_in_for
    source = "for i in [1]\n  x = i\n\n  x\nend"
    offenses = offenses(source)
    assert_equal(1, offenses.size, 'Expected offense not registered for empty line in for/end')
  end

  def test_registers_offense_for_empty_line_in_case
    source = "case 1\nwhen 1\n\n  :one\nend"
    offenses = offenses(source)
    assert_equal(1, offenses.size, 'Expected offense not registered for empty line in case/end')
  end

  def test_registers_offense_for_empty_line_in_case_in
    source = "case 1\nin 1\n\n  :one\nend"
    offenses = offenses(source)
    assert_equal(1, offenses.size, 'Expected offense not registered for empty line in case/in pattern')
  end

  def test_registers_offense_for_empty_line_in_begin
    source = "begin\n  x = 1\n\n  x\nend"
    offenses = offenses(source)
    assert_equal(1, offenses.size, 'Expected offense not registered for empty line in begin/end')
  end

  def test_registers_offense_for_empty_line_in_numblock
    source = "[1].each do\n  puts _1\n\n  puts _1\nend"
    offenses = offenses(source)
    assert_equal(1, offenses.size, 'Expected offense not registered for empty line in numbered block')
  end

  def test_registers_offense_for_multiple_empty_lines
    source = "loop do\n  x = 1\n\n\n  x\nend"
    offenses = offenses(source)
    assert_equal(2, offenses.size, 'Expected offenses not registered for multiple empty lines in block')
  end

  def test_allows_block_without_empty_lines
    source = "loop do\n  x = 1\n  x\nend"
    offenses = offenses(source)
    assert_equal(0, offenses.size, 'Block without empty lines should be allowed')
  end

  def test_allows_single_line_block
    source = '[1].each { |x| x + 1 }'
    offenses = offenses(source)
    assert_equal(0, offenses.size, 'Single line block should be allowed')
  end

  def test_allows_empty_block
    source = "loop do\nend"
    offenses = offenses(source)
    assert_equal(0, offenses.size, 'Empty block should be allowed')
  end

  def test_allows_top_level_empty_lines
    source = "x = 1\n\ny = 2"
    offenses = offenses(source)
    assert_equal(0, offenses.size, 'Top level empty lines should not be flagged')
  end

  def test_allows_empty_lines_between_methods
    source = "class Foo\n  def a\n    1\n  end\n\n  def b\n    2\n  end\nend"
    offenses = offenses(source)
    assert_equal(0, offenses.size, 'Empty line between class methods should not be flagged')
  end

  def test_deduplicates_nested_blocks
    source = "loop do\n  if true\n\n    x = 1\n  end\nend"
    offenses = offenses(source)
    assert_equal(1, offenses.size, 'Same empty line in nested blocks should be reported once')
  end

  def test_corrects_empty_line_in_block
    source = "loop do\n  x = 1\n\n  x\nend"
    corrected = correct(source)
    assert_equal("loop do\n  x = 1\n  x\nend", corrected, 'Empty line in block not removed')
  end

  def test_corrects_multiple_empty_lines
    source = "loop do\n  x = 1\n\n\n  x\nend"
    corrected = correct(source)
    assert_equal("loop do\n  x = 1\n  x\nend", corrected, 'Multiple empty lines in block not removed')
  end

  private

  def offenses(source)
    config = RuboCop::Config.new
    cop = RuboCop::Cop::Elegant::NoEmptyLinesInBlocks.new(config)
    commissioner = RuboCop::Cop::Commissioner.new([cop], [], raise_error: true)
    processed = RuboCop::ProcessedSource.new(source, Float(RUBY_VERSION[/[0-9]+.[0-9]+/]))
    result = commissioner.investigate(processed)
    result.offenses
  end

  def correct(source)
    config = RuboCop::Config.new
    cop = RuboCop::Cop::Elegant::NoEmptyLinesInBlocks.new(config, autocorrect: true)
    processed = RuboCop::ProcessedSource.new(source, Float(RUBY_VERSION[/[0-9]+.[0-9]+/]))
    commissioner = RuboCop::Cop::Commissioner.new([cop], [], raise_error: true)
    result = commissioner.investigate(processed)
    corrector = RuboCop::Cop::Corrector.new(processed.buffer)
    result.correctors.compact.each { |c| corrector.merge!(c) }
    corrector.rewrite
  end
end
