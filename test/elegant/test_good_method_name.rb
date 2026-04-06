# frozen_string_literal: true

require_relative '../../lib/rubocop-elegant'
# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'

class GoodMethodNameTest < Minitest::Test
  def test_allows_short_lowercase_method
    offenses = offenses('def foo; end')
    assert_equal(0, offenses.size, 'Short lowercase method should be allowed')
  end

  def test_rejects_method_with_underscore
    offenses = offenses('def foo_bar; end')
    assert_equal(1, offenses.size, 'Method with underscore should be rejected')
  end

  def test_rejects_method_with_uppercase
    offenses = offenses('def fooBar; end')
    assert_equal(1, offenses.size, 'Method with uppercase should be rejected')
  end

  def test_rejects_method_too_long
    offenses = offenses('def verylongmethodname; end')
    assert_equal(1, offenses.size, 'Method longer than 16 chars should be rejected')
  end

  def test_allows_bang_method
    offenses = offenses('def save!; end')
    assert_equal(0, offenses.size, 'Bang method should be allowed')
  end

  def test_allows_predicate_method
    offenses = offenses('def valid?; end')
    assert_equal(0, offenses.size, 'Predicate method should be allowed')
  end

  def test_allows_test_prefix
    offenses = offenses('def test_something_works; end')
    assert_equal(0, offenses.size, 'Method with test_ prefix should be allowed')
  end

  def test_allows_fake_prefix
    offenses = offenses('def fake_response; end')
    assert_equal(0, offenses.size, 'Method with fake_ prefix should be allowed')
  end

  def test_allows_the_prefix
    offenses = offenses('def the_answer; end')
    assert_equal(0, offenses.size, 'Method with the_ prefix should be allowed')
  end

  def test_allows_class_method
    offenses = offenses('def self.foo; end')
    assert_equal(0, offenses.size, 'Class method should be allowed')
  end

  def test_rejects_class_method_with_underscore
    offenses = offenses('def self.foo_bar; end')
    assert_equal(1, offenses.size, 'Class method with underscore should be rejected')
  end

  private

  def offenses(source)
    config = RuboCop::Config.new(
      'Elegant/GoodMethodName' => {
        'Enabled' => true,
        'Pattern' => '^((fake_|the_)?[a-z]{1,16}[!?]?|test_[a-z_]+)$'
      }
    )
    cop = RuboCop::Cop::Elegant::GoodMethodName.new(config)
    commissioner = RuboCop::Cop::Commissioner.new([cop], [], raise_error: true)
    processed = RuboCop::ProcessedSource.new(source, Float(RUBY_VERSION[/[0-9]+.[0-9]+/]))
    result = commissioner.investigate(processed)
    result.offenses
  end
end
