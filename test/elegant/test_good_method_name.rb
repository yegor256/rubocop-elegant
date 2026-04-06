# frozen_string_literal: true

require_relative '../../lib/rubocop-elegant'
# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'

class GoodMethodNameTest < Minitest::Test
  [
    ['def foo; end', 'short lowercase method'],
    ['def save!; end', 'bang method'],
    ['def valid?; end', 'predicate method'],
    ['def test_something_works; end', 'test_ prefix'],
    ['def fake_response; end', 'fake_ prefix'],
    ['def the_answer; end', 'the_ prefix'],
    ['def self.foo; end', 'class method']
  ].each do |source, description|
    define_method("test_allows_#{description.gsub(/\s+/, '_')}") do
      assert_equal(0, offenses(source).size, "#{description} should be allowed")
    end
  end

  [
    ['def foo_bar; end', 'underscore in name'],
    ['def fooBar; end', 'uppercase in name'],
    ['def verylongmethodname; end', 'longer than 16 chars'],
    ['def self.foo_bar; end', 'class method with underscore']
  ].each do |source, description|
    define_method("test_rejects_#{description.gsub(/\s+/, '_')}") do
      assert_equal(1, offenses(source).size, "#{description} should be rejected")
    end
  end

  private

  def offenses(source)
    path = File.expand_path('../../config/default.yml', __dir__)
    yaml = YAML.safe_load(File.read(path))
    config = RuboCop::Config.new('Elegant/GoodMethodName' => yaml['Elegant/GoodMethodName'])
    cop = RuboCop::Cop::Elegant::GoodMethodName.new(config)
    commissioner = RuboCop::Cop::Commissioner.new([cop], [], raise_error: true)
    processed = RuboCop::ProcessedSource.new(source, Float(RUBY_VERSION[/[0-9]+.[0-9]+/]))
    result = commissioner.investigate(processed)
    result.offenses
  end
end
