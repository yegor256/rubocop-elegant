# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/rubocop-elegant'
require_relative '../test__helper'

class SpdxOnTopTest < Minitest::Test
  ALLOWED = {
    'empty_file' => '',
    'file_without_any_spdx_comment' => "require 'foo'\nclass Bar\nend",
    'spdx_on_the_very_first_line' => "# SPDX-FileCopyrightText: Copyright (c) 2026\nrequire 'foo'",
    'magic_comment_above_spdx' =>
      "# frozen_string_literal: true\n\n# SPDX-FileCopyrightText: Copyright (c) 2026\n\nrequire 'foo'",
    'shebang_above_spdx' => "#!/usr/bin/env ruby\n# SPDX-FileCopyrightText: Copyright (c) 2026\nputs 1",
    'blank_lines_above_spdx' => "\n\n# SPDX-FileCopyrightText: Copyright (c) 2026\nputs 1",
    'rubocop_directive_above_spdx' =>
      "# rubocop:disable Style/Foo\n# SPDX-FileCopyrightText: Copyright (c) 2026\nputs 1",
    'indented_comment_above_spdx' => "  # note\n# SPDX-FileCopyrightText: Copyright (c) 2026\nputs 1",
    'code_below_the_first_spdx_tag_only' =>
      "# SPDX-FileCopyrightText: Copyright (c) 2025\nputs 1\n# SPDX-FileCopyrightText: Copyright (c) 2026\n",
    'all_code_below_spdx' => "# SPDX-FileCopyrightText: Copyright (c) 2026\nrequire 'foo'\nrequire 'bar'"
  }.freeze
  public_constant :ALLOWED

  VIOLATIONS = {
    'require_above_spdx' =>
      ["# frozen_string_literal: true\n\nrequire 'factbase'\n# SPDX-FileCopyrightText: Copyright (c) 2026\n", 1],
    'class_above_spdx' => ["class Foo\nend\n# SPDX-FileCopyrightText: Copyright (c) 2026\n", 1],
    'many_lines_of_code_above_spdx' =>
      ["require 'a'\nrequire 'b'\n# SPDX-FileCopyrightText: Copyright (c) 2026\n", 1],
    'code_with_trailing_comment_above_spdx' =>
      ["require 'foo' # note\n# SPDX-FileCopyrightText: Copyright (c) 2026\n", 1]
  }.freeze
  public_constant :VIOLATIONS

  ALLOWED.each do |name, source|
    define_method("test_allows_#{name}") do
      total = offenses(source).size
      assert_equal(0, total, "Expected no offense in #{name.tr('_', ' ')}, got #{total}")
    end
  end

  VIOLATIONS.each do |name, (source, count)|
    define_method("test_registers_offense_for_#{name}") do
      total = offenses(source).size
      assert_equal(count, total, "Expected #{count} offense(s) for #{name.tr('_', ' ')}, got #{total}")
    end
  end

  def test_points_at_the_first_line_of_code
    line = offenses("# note\n\nrequire 'foo'\n# SPDX-FileCopyrightText: (c) 2026\n").first.location.line
    assert_equal(3, line, "Expected the offense on line 3, got #{line}")
  end

  private

  def offenses(source)
    RuboCop::Cop::Commissioner.new(
      [RuboCop::Cop::Elegant::SpdxOnTop.new(RuboCop::Config.new)], [], raise_error: true
    ).investigate(
      RuboCop::ProcessedSource.new(source, Float(RUBY_VERSION[/[0-9]+.[0-9]+/]))
    ).offenses
  end
end
