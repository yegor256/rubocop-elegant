# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/rubocop-elegant'
require_relative '../test__helper'

class MonotonicIndentsTest < Minitest::Test
  ALLOWED = {
    'single_line_source' => 'x = 1',
    'two_lines_at_same_indent' => "a = 1\nb = 2",
    'two_space_step_into_method' => "def foo\n  bar\nend",
    'nested_two_space_steps' => "def foo\n  if x\n    y\n  end\nend",
    'dedent_then_re_indent_by_two' => "  a\nb\n  c",
    'large_dedent_is_allowed' => "        a\nb",
    'blank_lines_are_skipped' => "def foo\n\n  bar\n\nend",
    'comment_lines_at_two_step' => "# top\n  # nested",
    'heredoc_body_with_irregular_indent' => "foo(<<~END)\n      bar\n        baz\n    END",
    'consecutive_two_space_increments' => "a\n  b\n    c\n      d\n        e"
  }.freeze
  public_constant :ALLOWED

  VIOLATIONS = {
    'one_space_step' => ["def foo\n bar\nend", 1],
    'three_space_step' => ["def foo\n   bar\nend", 1],
    'four_space_step' => ["def foo\n    bar\nend", 1],
    'two_independent_jumps' => ["a = 1\n    b = 2\n  c = 3\n      d = 4", 2],
    'jump_after_dedent' => ["  a\nb\n      c", 1]
  }.freeze
  public_constant :VIOLATIONS

  ALLOWED.each do |name, source|
    define_method("test_allows_#{name}") do
      total = offenses(source).size
      assert_equal(0, total, "Expected no offense in #{name.tr('_', ' ')}, got #{total}")
    end
  end

  VIOLATIONS.each do |name, (source, count)|
    define_method("test_rejects_#{name}") do
      total = offenses(source).size
      assert_equal(count, total, "Expected #{count} offense(s) for #{name.tr('_', ' ')}, got #{total}")
    end
  end

  private

  def offenses(source)
    RuboCop::Cop::Commissioner.new(
      [RuboCop::Cop::Elegant::MonotonicIndents.new(RuboCop::Config.new)], [], raise_error: true
    ).investigate(
      RuboCop::ProcessedSource.new(source, Float(RUBY_VERSION[/[0-9]+.[0-9]+/]))
    ).offenses
  end
end
