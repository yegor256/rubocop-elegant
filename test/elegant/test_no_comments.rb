# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require_relative '../../lib/rubocop-elegant'

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
    offenses = inspect_source("# #{spdx('License-Identifier')}: MIT\ndef foo; end")
    assert_equal(0, offenses.size, 'SPDX-License-Identifier should be allowed')
  end

  def test_allows_spdx_file_copyright
    offenses = inspect_source("# #{spdx('FileCopyrightText')}: Copyright (c) 2019-2026 Author\ndef foo; end")
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
    source = "# #{spdx('License-Identifier')}: MIT\n# regular comment\ndef foo; end"
    offenses = inspect_source(source)
    assert_equal(1, offenses.size, 'Only regular comment should be flagged')
  end

  def test_allows_frozen_string_literal
    offenses = inspect_source("# frozen_string_literal: true\ndef foo; end")
    assert_equal(0, offenses.size, 'frozen_string_literal magic comment should be allowed')
  end

  def test_allows_encoding_magic_comment
    offenses = inspect_source("# encoding: utf-8\ndef foo; end")
    assert_equal(0, offenses.size, 'encoding magic comment should be allowed')
  end

  def test_allows_rubocop_disable
    offenses = inspect_source("# rubocop:disable Style/Foo\ndef foo; end")
    assert_equal(0, offenses.size, 'rubocop:disable comment should be allowed')
  end

  def test_allows_rubocop_enable
    offenses = inspect_source("# rubocop:enable Style/Foo\ndef foo; end")
    assert_equal(0, offenses.size, 'rubocop:enable comment should be allowed')
  end

  def test_allows_rubocop_todo
    offenses = inspect_source("# rubocop:todo Style/Foo\ndef foo; end")
    assert_equal(0, offenses.size, 'rubocop:todo comment should be allowed')
  end

  def test_autocorrects_preserves_magic_comment
    source = "# frozen_string_literal: true\n# bad comment\ndef foo; end"
    corrected = autocorrect(source)
    assert_equal("# frozen_string_literal: true\ndef foo; end", corrected, 'Magic comment was removed')
  end

  def test_autocorrects_standalone_comment
    source = "# comment\ndef foo; end"
    corrected = autocorrect(source)
    assert_equal('def foo; end', corrected, 'Standalone comment not removed')
  end

  def test_autocorrects_inline_comment
    source = 'def foo; end # inline'
    corrected = autocorrect(source)
    assert_equal('def foo; end', corrected, 'Inline comment not removed')
  end

  def test_autocorrects_preserves_spdx
    source = "# #{spdx('License-Identifier')}: MIT\n# bad comment\ndef foo; end"
    corrected = autocorrect(source)
    assert_equal("# #{spdx('License-Identifier')}: MIT\ndef foo; end", corrected, 'SPDX comment was removed')
  end

  def test_autocorrects_multiple_comments
    source = "# first\n# second\ndef foo; end"
    corrected = autocorrect(source)
    assert_equal('def foo; end', corrected, 'Multiple comments not removed')
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

  def autocorrect(source)
    config = RuboCop::Config.new
    cop = RuboCop::Cop::Elegant::NoComments.new(config, autocorrect: true)
    processed = RuboCop::ProcessedSource.new(source, RUBY_VERSION.to_f)
    commissioner = RuboCop::Cop::Commissioner.new([cop], [], raise_error: true)
    result = commissioner.investigate(processed)
    corrector = RuboCop::Cop::Corrector.new(processed.buffer)
    result.correctors.compact.each { |c| corrector.merge!(c) }
    corrector.rewrite
  end

  def spdx(suffix)
    "SPDX-#{suffix}"
  end
end
