# frozen_string_literal: true

require_relative '../../lib/rubocop-elegant'
# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require 'fileutils'
require 'tmpdir'

class NoCommentsTest < Minitest::Test
  def test_registers_offense_for_regular_comment
    assert_equal(
      1, offenses("# This is a comment\ndef foo; end").size,
      'Expected offense not registered for regular comment'
    )
  end

  def test_registers_offense_for_inline_comment
    assert_equal(1, offenses('def foo; end # inline').size, 'Expected offense not registered for inline comment')
  end

  def test_allows_spdx_license_identifier
    assert_equal(
      0, offenses("# #{spdx('License-Identifier')}: MIT\ndef foo; end").size,
      'SPDX-License-Identifier should be allowed'
    )
  end

  def test_allows_spdx_file_copyright
    assert_equal(
      0,
      offenses("# #{spdx('FileCopyrightText')}: Copyright (c) 2019-2026 Author\ndef foo; end").size,
      'SPDX-FileCopyrightText should be allowed'
    )
  end

  def test_registers_offense_for_multiple_comments
    assert_equal(
      2, offenses("# first\n# second\ndef foo; end").size,
      'Expected offenses not registered for multiple comments'
    )
  end

  def test_allows_code_without_comments
    assert_equal(0, offenses('def foo; end').size, 'Code without comments should be allowed')
  end

  def test_mixed_spdx_and_regular_comments
    assert_equal(
      1,
      offenses("# #{spdx('License-Identifier')}: MIT\n# regular comment\ndef foo; end").size,
      'Only regular comment should be flagged'
    )
  end

  def test_allows_frozen_string_literal
    assert_equal(
      0, offenses("# frozen_string_literal: true\ndef foo; end").size,
      'frozen_string_literal magic comment should be allowed'
    )
  end

  def test_allows_encoding_magic_comment
    assert_equal(
      0, offenses("# encoding: utf-8\ndef foo; end").size,
      'encoding magic comment should be allowed'
    )
  end

  def test_allows_rubocop_disable
    assert_equal(
      0, offenses("# rubocop:disable Style/Foo\ndef foo; end").size,
      'rubocop:disable comment should be allowed'
    )
  end

  def test_allows_rubocop_enable
    assert_equal(
      0, offenses("# rubocop:enable Style/Foo\ndef foo; end").size,
      'rubocop:enable comment should be allowed'
    )
  end

  def test_allows_rubocop_todo
    assert_equal(0, offenses("# rubocop:todo Style/Foo\ndef foo; end").size, 'rubocop:todo comment should be allowed')
  end

  def test_corrects_preserves_magic_comment
    assert_equal(
      "# frozen_string_literal: true\ndef foo; end",
      correct("# frozen_string_literal: true\n# bad comment\ndef foo; end"),
      'Magic comment was removed'
    )
  end

  def test_corrects_standalone_comment
    assert_equal('def foo; end', correct("# comment\ndef foo; end"), 'Standalone comment not removed')
  end

  def test_corrects_inline_comment
    assert_equal('def foo; end', correct('def foo; end # inline'), 'Inline comment not removed')
  end

  def test_corrects_preserves_spdx
    assert_equal(
      "# #{spdx('License-Identifier')}: MIT\ndef foo; end",
      correct("# #{spdx('License-Identifier')}: MIT\n# bad comment\ndef foo; end"),
      'SPDX comment was removed'
    )
  end

  def test_corrects_multiple_comments
    assert_equal('def foo; end', correct("# first\n# second\ndef foo; end"), 'Multiple comments not removed')
  end

  def test_allows_method_docblock_when_gemspec_present
    Dir.mktmpdir do |dir|
      FileUtils.touch(File.join(dir, 'foo.gemspec'))
      assert_equal(
        0,
        scan("# Documents the method.\ndef foo; end", dir).size,
        'Method docblock should be allowed when gemspec present'
      )
    end
  end

  def test_allows_class_docblock_when_gemspec_present
    Dir.mktmpdir do |dir|
      FileUtils.touch(File.join(dir, 'foo.gemspec'))
      assert_equal(
        0,
        scan("# Documents the class.\nclass Foo; end", dir).size,
        'Class docblock should be allowed when gemspec present'
      )
    end
  end

  def test_allows_module_docblock_when_gemspec_present
    Dir.mktmpdir do |dir|
      FileUtils.touch(File.join(dir, 'foo.gemspec'))
      assert_equal(
        0,
        scan("# Documents the module.\nmodule Foo; end", dir).size,
        'Module docblock should be allowed when gemspec present'
      )
    end
  end

  def test_allows_multiline_docblock_with_gemspec
    Dir.mktmpdir do |dir|
      FileUtils.touch(File.join(dir, 'foo.gemspec'))
      assert_equal(
        0,
        scan("# First line of docblock.\n# Second line of docblock.\ndef foo; end", dir).size,
        'Multiline docblock should be allowed when gemspec present'
      )
    end
  end

  def test_disallows_docblock_when_no_gemspec
    Dir.mktmpdir do |dir|
      assert_equal(
        1,
        scan("# Documents the method.\ndef foo; end", dir).size,
        'Docblock should be disallowed when no gemspec'
      )
    end
  end

  def test_disallows_non_docblock_comment_with_gemspec
    Dir.mktmpdir do |dir|
      FileUtils.touch(File.join(dir, 'foo.gemspec'))
      assert_equal(
        1,
        scan("# random comment\nx = 1\ndef foo; end", dir).size,
        'Non-docblock comment should be disallowed even with gemspec'
      )
    end
  end

  private

  def offenses(source)
    RuboCop::Cop::Commissioner.new(
      [RuboCop::Cop::Elegant::NoComments.new(RuboCop::Config.new)], [], raise_error: true
    ).investigate(
      RuboCop::ProcessedSource.new(source, Float(RUBY_VERSION[/[0-9]+.[0-9]+/]))
    ).offenses
  end

  def correct(source)
    processed = RuboCop::ProcessedSource.new(source, Float(RUBY_VERSION[/[0-9]+.[0-9]+/]))
    corrector = RuboCop::Cop::Corrector.new(processed.buffer)
    RuboCop::Cop::Commissioner.new(
      [RuboCop::Cop::Elegant::NoComments.new(RuboCop::Config.new, autocorrect: true)], [], raise_error: true
    ).investigate(processed).correctors.compact.each { |c| corrector.merge!(c) }
    corrector.rewrite
  end

  def spdx(suffix)
    "SPDX-#{suffix}"
  end

  def scan(source, dir)
    path = File.join(dir, 'test_file.rb')
    File.write(path, source)
    RuboCop::Cop::Commissioner.new(
      [RuboCop::Cop::Elegant::NoComments.new(RuboCop::Config.new)], [], raise_error: true
    ).investigate(
      RuboCop::ProcessedSource.new(source, Float(RUBY_VERSION[/[0-9]+.[0-9]+/]), path)
    ).offenses
  end
end
