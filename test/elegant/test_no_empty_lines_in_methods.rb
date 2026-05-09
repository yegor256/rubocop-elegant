# frozen_string_literal: true

require_relative '../../lib/rubocop-elegant'
# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'

class NoEmptyLinesInMethodsTest < Minitest::Test
  def test_registers_offense_for_empty_line_in_method
    assert_equal(
      1, offenses("def foo\n  x = 1\n\n  x\nend").size,
      'Expected offense not registered for empty line in method'
    )
  end

  def test_registers_offense_for_multiple_empty_lines
    assert_equal(
      2, offenses("def foo\n  x = 1\n\n\n  x\nend").size,
      'Expected offenses not registered for multiple empty lines'
    )
  end

  def test_allows_method_without_empty_lines
    assert_equal(0, offenses("def foo\n  x = 1\n  x\nend").size, 'Method without empty lines should be allowed')
  end

  def test_allows_single_line_method
    assert_equal(0, offenses('def foo; 42; end').size, 'Single line method should be allowed')
  end

  def test_allows_empty_method
    assert_equal(0, offenses("def foo\nend").size, 'Empty method should be allowed')
  end

  def test_registers_offense_in_class_method
    assert_equal(
      1, offenses("def self.foo\n  x = 1\n\n  x\nend").size,
      'Expected offense not registered for class method'
    )
  end

  def test_corrects_empty_line
    assert_equal(
      "def foo\n  x = 1\n  x\nend",
      correct("def foo\n  x = 1\n\n  x\nend"),
      'Empty line not removed'
    )
  end

  def test_corrects_multiple_empty_lines
    assert_equal(
      "def foo\n  x = 1\n  x\nend",
      correct("def foo\n  x = 1\n\n\n  x\nend"),
      'Multiple empty lines not removed'
    )
  end

  private

  def offenses(source)
    RuboCop::Cop::Commissioner.new(
      [RuboCop::Cop::Elegant::NoEmptyLinesInMethods.new(RuboCop::Config.new)], [], raise_error: true
    ).investigate(
      RuboCop::ProcessedSource.new(source, Float(RUBY_VERSION[/[0-9]+.[0-9]+/]))
    ).offenses
  end

  def correct(source)
    processed = RuboCop::ProcessedSource.new(source, Float(RUBY_VERSION[/[0-9]+.[0-9]+/]))
    corrector = RuboCop::Cop::Corrector.new(processed.buffer)
    RuboCop::Cop::Commissioner.new(
      [RuboCop::Cop::Elegant::NoEmptyLinesInMethods.new(RuboCop::Config.new, autocorrect: true)], [], raise_error: true
    ).investigate(processed).correctors.compact.each { |c| corrector.merge!(c) }
    corrector.rewrite
  end
end
