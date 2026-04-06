# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test/test__helper'
require_relative '../lib/rubocop-elegant'

class RubocopElegantTest < Minitest::Test
  def test_reports_version
    refute_nil(RuboCop::Elegant::VERSION, 'Version is not defined')
  end

  def test_plugin_about_returns_info
    plugin = RuboCop::Elegant::Plugin.new
    about = plugin.about
    assert_equal('rubocop-elegant', about.name, 'Plugin name is wrong')
  end

  def test_plugin_supports_rubocop
    plugin = RuboCop::Elegant::Plugin.new
    context = Struct.new(:engine).new(:rubocop)
    assert(plugin.supported?(context), 'Plugin should support rubocop engine')
  end

  def test_plugin_does_not_support_other_engines
    plugin = RuboCop::Elegant::Plugin.new
    context = Struct.new(:engine).new(:other)
    refute(plugin.supported?(context), 'Plugin should not support other engines')
  end

  def test_plugin_rules_returns_path
    plugin = RuboCop::Elegant::Plugin.new
    context = Struct.new(:engine).new(:rubocop)
    rules = plugin.rules(context)
    assert_equal(:path, rules.type, 'Rules type should be path')
  end
end
