# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require_relative '../../lib/rubocop-elegant'

class NoEmptyLinesInMethodsTest < Minitest::Test
  def test_registers_offense_for_empty_line_in_method
    source = "def foo\n  x = 1\n\n  x\nend"
    offenses = inspect_source(source)
    assert_equal(1, offenses.size, 'Expected offense not registered for empty line in method')
  end

  def test_registers_offense_for_multiple_empty_lines
    source = "def foo\n  x = 1\n\n\n  x\nend"
    offenses = inspect_source(source)
    assert_equal(2, offenses.size, 'Expected offenses not registered for multiple empty lines')
  end

  def test_allows_method_without_empty_lines
    source = "def foo\n  x = 1\n  x\nend"
    offenses = inspect_source(source)
    assert_equal(0, offenses.size, 'Method without empty lines should be allowed')
  end

  def test_allows_single_line_method
    source = 'def foo; 42; end'
    offenses = inspect_source(source)
    assert_equal(0, offenses.size, 'Single line method should be allowed')
  end

  def test_allows_empty_method
    source = "def foo\nend"
    offenses = inspect_source(source)
    assert_equal(0, offenses.size, 'Empty method should be allowed')
  end

  def test_registers_offense_in_class_method
    source = "def self.foo\n  x = 1\n\n  x\nend"
    offenses = inspect_source(source)
    assert_equal(1, offenses.size, 'Expected offense not registered for class method')
  end

  def test_autocorrects_empty_line
    source = "def foo\n  x = 1\n\n  x\nend"
    corrected = autocorrect(source)
    assert_equal("def foo\n  x = 1\n  x\nend", corrected, 'Empty line not removed')
  end

  def test_autocorrects_multiple_empty_lines
    source = "def foo\n  x = 1\n\n\n  x\nend"
    corrected = autocorrect(source)
    assert_equal("def foo\n  x = 1\n  x\nend", corrected, 'Multiple empty lines not removed')
  end

  private

  def inspect_source(source)
    config = RuboCop::Config.new
    cop = RuboCop::Cop::Elegant::NoEmptyLinesInMethods.new(config)
    commissioner = RuboCop::Cop::Commissioner.new([cop], [], raise_error: true)
    processed = RuboCop::ProcessedSource.new(source, RUBY_VERSION.to_f)
    result = commissioner.investigate(processed)
    result.offenses
  end

  def autocorrect(source)
    config = RuboCop::Config.new
    cop = RuboCop::Cop::Elegant::NoEmptyLinesInMethods.new(config, autocorrect: true)
    processed = RuboCop::ProcessedSource.new(source, RUBY_VERSION.to_f)
    commissioner = RuboCop::Cop::Commissioner.new([cop], [], raise_error: true)
    result = commissioner.investigate(processed)
    corrector = RuboCop::Cop::Corrector.new(processed.buffer)
    result.correctors.compact.each { |c| corrector.merge!(c) }
    corrector.rewrite
  end
end
