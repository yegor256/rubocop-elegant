# frozen_string_literal: true

require_relative '../../lib/rubocop-elegant'
# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'

class GoodVariableNameTest < Minitest::Test
  def test_allows_short_lowercase_variable
    offenses = offenses('foo = 1')
    assert_equal(0, offenses.size, 'Short lowercase variable should be allowed')
  end

  def test_rejects_variable_with_underscore
    offenses = offenses('foo_bar = 1')
    assert_equal(1, offenses.size, 'Variable with underscore should be rejected')
  end

  def test_rejects_variable_with_uppercase
    offenses = offenses('fooBar = 1')
    assert_equal(1, offenses.size, 'Variable with uppercase should be rejected')
  end

  def test_rejects_variable_too_long
    offenses = offenses('verylongvariablex = 1')
    assert_equal(1, offenses.size, 'Variable longer than 16 chars should be rejected')
  end

  def test_allows_instance_variable
    offenses = offenses('@foo = 1')
    assert_equal(0, offenses.size, 'Instance variable should be allowed')
  end

  def test_allows_class_variable
    offenses = offenses('@@foo = 1')
    assert_equal(0, offenses.size, 'Class variable should be allowed')
  end

  def test_allows_global_variable
    offenses = offenses('$foo = 1')
    assert_equal(0, offenses.size, 'Global variable should be allowed')
  end

  def test_allows_test_prefix
    offenses = offenses('test_foo = 1')
    assert_equal(0, offenses.size, 'Variable with test_ prefix should be allowed')
  end

  def test_allows_fake_prefix
    offenses = offenses('fake_bar = 1')
    assert_equal(0, offenses.size, 'Variable with fake_ prefix should be allowed')
  end

  def test_allows_the_prefix
    offenses = offenses('the_item = 1')
    assert_equal(0, offenses.size, 'Variable with the_ prefix should be allowed')
  end

  def test_rejects_instance_variable_with_underscore
    offenses = offenses('@foo_bar = 1')
    assert_equal(1, offenses.size, 'Instance variable with underscore should be rejected')
  end

  private

  def offenses(source)
    config = RuboCop::Config.new(
      'Elegant/GoodVariableName' => {
        'Enabled' => true,
        'Pattern' => '^(@|@@|\$|the_|test_|fake_)?[a-z]{1,16}$'
      }
    )
    cop = RuboCop::Cop::Elegant::GoodVariableName.new(config)
    commissioner = RuboCop::Cop::Commissioner.new([cop], [], raise_error: true)
    processed = RuboCop::ProcessedSource.new(source, Float(RUBY_VERSION[/[0-9]+.[0-9]+/]))
    result = commissioner.investigate(processed)
    result.offenses
  end
end
