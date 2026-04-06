# frozen_string_literal: true

require_relative '../../lib/rubocop-elegant'
# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'

class GoodVariableNameTest < Minitest::Test
  [
    ['foo', 'short lowercase variable'],
    ['@foo', 'instance variable'],
    ['@@foo', 'class variable'],
    ['$foo', 'global variable'],
    ['test_foo', 'test_ prefix'],
    ['fake_bar', 'fake_ prefix'],
    ['the_item', 'the_ prefix'],
    ['@the_book', 'instance variable with the_ prefix'],
    ['@@the_book', 'class variable with the_ prefix'],
    ['@test_book', 'instance variable with test_ prefix'],
    ['$fake_book', 'global variable with fake_ prefix']
  ].each do |variable, description|
    define_method("test_allows_#{description.gsub(/\s+/, '_')}") do
      assert_equal(0, offenses("#{variable} = 1").size, "#{description} should be allowed")
    end
  end

  [
    ['foo_bar', 'underscore in name'],
    ['fooBar', 'uppercase in name'],
    ['verylongvariablex', 'longer than 16 chars'],
    ['@foo_bar', 'instance variable with underscore']
  ].each do |variable, description|
    define_method("test_rejects_#{description.gsub(/\s+/, '_')}") do
      assert_equal(1, offenses("#{variable} = 1").size, "#{description} should be rejected")
    end
  end

  private

  def offenses(source)
    path = File.expand_path('../../config/default.yml', __dir__)
    yaml = YAML.safe_load(File.read(path))
    config = RuboCop::Config.new('Elegant/GoodVariableName' => yaml['Elegant/GoodVariableName'])
    cop = RuboCop::Cop::Elegant::GoodVariableName.new(config)
    commissioner = RuboCop::Cop::Commissioner.new([cop], [], raise_error: true)
    processed = RuboCop::ProcessedSource.new(source, Float(RUBY_VERSION[/[0-9]+.[0-9]+/]))
    result = commissioner.investigate(processed)
    result.offenses
  end
end
