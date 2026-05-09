# frozen_string_literal: true

require_relative '../lib/rubocop-elegant'
# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test/test__helper'

class RubocopElegantTest < Minitest::Test
  def test_reports_version
    refute_nil(RuboCop::Elegant::VERSION, 'Version is not defined')
  end

  def test_plugin_about_returns_info
    assert_equal('rubocop-elegant', RuboCop::Elegant::Plugin.new.about.name, 'Plugin name is wrong')
  end

  def test_plugin_supports_rubocop
    assert(
      RuboCop::Elegant::Plugin.new.supported?(Struct.new(:engine).new(:rubocop)),
      'Plugin should support rubocop engine'
    )
  end

  def test_plugin_does_not_support_other_engines
    refute(
      RuboCop::Elegant::Plugin.new.supported?(Struct.new(:engine).new(:other)),
      'Plugin should not support other engines'
    )
  end

  def test_plugin_rules_returns_path
    assert_equal(
      :path,
      RuboCop::Elegant::Plugin.new.rules(Struct.new(:engine).new(:rubocop)).type,
      'Rules type should be path'
    )
  end
end
