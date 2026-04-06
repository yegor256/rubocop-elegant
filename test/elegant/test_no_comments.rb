# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require_relative '../../lib/rubocop-elegant'

# Test for NoComments cop.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2026 Yegor Bugayenko
# License:: MIT
class NoCommentsTest < Minitest::Test
  def test_registers_offense_for_regular_comment
    offenses = inspect_source("# This is a comment\ndef foo; end")
    assert_equal(1, offenses.size, 'Expected offense not registered for regular comment')
  end

  def test_registers_offense_for_inline_comment
    offenses = inspect_source('def foo; end # inline')
    assert_equal(1, offenses.size, 'Expected offense not registered for inline comment')
  end

  def test_allows_spdx_license_identifier
    offenses = inspect_source(
      [
        '# SPDX-License-Identifier: MIT
        ',
        'def foo; end'
      ].join("\n")
    )
    assert_equal(0, offenses.size, 'SPDX-License-Identifier should be allowed')
  end

  def test_allows_spdx_file_copyright
    offenses = inspect_source("# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Author\ndef foo; end")
    assert_equal(0, offenses.size, 'SPDX-FileCopyrightText should be allowed')
  end

  def test_registers_offense_for_multiple_comments
    offenses = inspect_source("# first\n# second\ndef foo; end")
    assert_equal(2, offenses.size, 'Expected offenses not registered for multiple comments')
  end

  def test_allows_code_without_comments
    offenses = inspect_source('def foo; end')
    assert_equal(0, offenses.size, 'Code without comments should be allowed')
  end

  def test_mixed_spdx_and_regular_comments
    source = [
      '# SPDX-License-Identifier: MIT
      ',
      '# regular comment',
      'def foo; end'
    ].join("\n")
    offenses = inspect_source(source)
    assert_equal(1, offenses.size, 'Only regular comment should be flagged')
  end

  private

  def inspect_source(source)
    config = RuboCop::Config.new
    cop = RuboCop::Cop::Elegant::NoComments.new(config)
    commissioner = RuboCop::Cop::Commissioner.new([cop], [], raise_error: true)
    processed = RuboCop::ProcessedSource.new(source, RUBY_VERSION.to_f)
    result = commissioner.investigate(processed)
    result.offenses
  end
end
