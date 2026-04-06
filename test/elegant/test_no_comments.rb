# frozen_string_literal: true

require_relative '../../lib/rubocop-elegant'
# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require 'fileutils'
require 'tmpdir'

class NoCommentsTest < Minitest::Test
  def test_registers_offense_for_regular_comment
    offenses = offenses("# This is a comment\ndef foo; end")
    assert_equal(1, offenses.size, 'Expected offense not registered for regular comment')
  end

  def test_registers_offense_for_inline_comment
    offenses = offenses('def foo; end # inline')
    assert_equal(1, offenses.size, 'Expected offense not registered for inline comment')
  end

  def test_allows_spdx_license_identifier
    offenses = offenses("# #{spdx('License-Identifier')}: MIT\ndef foo; end")
    assert_equal(0, offenses.size, 'SPDX-License-Identifier should be allowed')
  end

  def test_allows_spdx_file_copyright
    offenses = offenses("# #{spdx('FileCopyrightText')}: Copyright (c) 2019-2026 Author\ndef foo; end")
    assert_equal(0, offenses.size, 'SPDX-FileCopyrightText should be allowed')
  end

  def test_registers_offense_for_multiple_comments
    offenses = offenses("# first\n# second\ndef foo; end")
    assert_equal(2, offenses.size, 'Expected offenses not registered for multiple comments')
  end

  def test_allows_code_without_comments
    offenses = offenses('def foo; end')
    assert_equal(0, offenses.size, 'Code without comments should be allowed')
  end

  def test_mixed_spdx_and_regular_comments
    source = "# #{spdx('License-Identifier')}: MIT\n# regular comment\ndef foo; end"
    offenses = offenses(source)
    assert_equal(1, offenses.size, 'Only regular comment should be flagged')
  end

  def test_allows_frozen_string_literal
    offenses = offenses("# frozen_string_literal: true\ndef foo; end")
    assert_equal(0, offenses.size, 'frozen_string_literal magic comment should be allowed')
  end

  def test_allows_encoding_magic_comment
    offenses = offenses("# encoding: utf-8\ndef foo; end")
    assert_equal(0, offenses.size, 'encoding magic comment should be allowed')
  end

  def test_allows_rubocop_disable
    offenses = offenses("# rubocop:disable Style/Foo\ndef foo; end")
    assert_equal(0, offenses.size, 'rubocop:disable comment should be allowed')
  end

  def test_allows_rubocop_enable
    offenses = offenses("# rubocop:enable Style/Foo\ndef foo; end")
    assert_equal(0, offenses.size, 'rubocop:enable comment should be allowed')
  end

  def test_allows_rubocop_todo
    offenses = offenses("# rubocop:todo Style/Foo\ndef foo; end")
    assert_equal(0, offenses.size, 'rubocop:todo comment should be allowed')
  end

  def test_corrects_preserves_magic_comment
    source = "# frozen_string_literal: true\n# bad comment\ndef foo; end"
    corrected = correct(source)
    assert_equal("# frozen_string_literal: true\ndef foo; end", corrected, 'Magic comment was removed')
  end

  def test_corrects_standalone_comment
    source = "# comment\ndef foo; end"
    corrected = correct(source)
    assert_equal('def foo; end', corrected, 'Standalone comment not removed')
  end

  def test_corrects_inline_comment
    source = 'def foo; end # inline'
    corrected = correct(source)
    assert_equal('def foo; end', corrected, 'Inline comment not removed')
  end

  def test_corrects_preserves_spdx
    source = "# #{spdx('License-Identifier')}: MIT\n# bad comment\ndef foo; end"
    corrected = correct(source)
    assert_equal("# #{spdx('License-Identifier')}: MIT\ndef foo; end", corrected, 'SPDX comment was removed')
  end

  def test_corrects_multiple_comments
    source = "# first\n# second\ndef foo; end"
    corrected = correct(source)
    assert_equal('def foo; end', corrected, 'Multiple comments not removed')
  end

  def test_allows_method_docblock_when_gemspec_present
    Dir.mktmpdir do |dir|
      FileUtils.touch(File.join(dir, 'foo.gemspec'))
      source = "# Documents the method.\ndef foo; end"
      offenses = scan(source, dir)
      assert_equal(0, offenses.size, 'Method docblock should be allowed when gemspec present')
    end
  end

  def test_allows_class_docblock_when_gemspec_present
    Dir.mktmpdir do |dir|
      FileUtils.touch(File.join(dir, 'foo.gemspec'))
      source = "# Documents the class.\nclass Foo; end"
      offenses = scan(source, dir)
      assert_equal(0, offenses.size, 'Class docblock should be allowed when gemspec present')
    end
  end

  def test_allows_module_docblock_when_gemspec_present
    Dir.mktmpdir do |dir|
      FileUtils.touch(File.join(dir, 'foo.gemspec'))
      source = "# Documents the module.\nmodule Foo; end"
      offenses = scan(source, dir)
      assert_equal(0, offenses.size, 'Module docblock should be allowed when gemspec present')
    end
  end

  def test_allows_multiline_docblock_when_gemspec_present
    Dir.mktmpdir do |dir|
      FileUtils.touch(File.join(dir, 'foo.gemspec'))
      source = "# First line of docblock.\n# Second line of docblock.\ndef foo; end"
      offenses = scan(source, dir)
      assert_equal(0, offenses.size, 'Multiline docblock should be allowed when gemspec present')
    end
  end

  def test_disallows_docblock_when_no_gemspec
    Dir.mktmpdir do |dir|
      source = "# Documents the method.\ndef foo; end"
      offenses = scan(source, dir)
      assert_equal(1, offenses.size, 'Docblock should be disallowed when no gemspec')
    end
  end

  def test_disallows_non_docblock_comment_even_with_gemspec
    Dir.mktmpdir do |dir|
      FileUtils.touch(File.join(dir, 'foo.gemspec'))
      source = "# random comment\nx = 1\ndef foo; end"
      offenses = scan(source, dir)
      assert_equal(1, offenses.size, 'Non-docblock comment should be disallowed even with gemspec')
    end
  end

  private

  def offenses(source)
    config = RuboCop::Config.new
    cop = RuboCop::Cop::Elegant::NoComments.new(config)
    commissioner = RuboCop::Cop::Commissioner.new([cop], [], raise_error: true)
    processed = RuboCop::ProcessedSource.new(source, Float(RUBY_VERSION[/[0-9]+.[0-9]+/]))
    result = commissioner.investigate(processed)
    result.offenses
  end

  def correct(source)
    config = RuboCop::Config.new
    cop = RuboCop::Cop::Elegant::NoComments.new(config, autocorrect: true)
    processed = RuboCop::ProcessedSource.new(source, Float(RUBY_VERSION[/[0-9]+.[0-9]+/]))
    commissioner = RuboCop::Cop::Commissioner.new([cop], [], raise_error: true)
    result = commissioner.investigate(processed)
    corrector = RuboCop::Cop::Corrector.new(processed.buffer)
    result.correctors.compact.each { |c| corrector.merge!(c) }
    corrector.rewrite
  end

  def spdx(suffix)
    "SPDX-#{suffix}"
  end

  def scan(source, dir)
    path = File.join(dir, 'test_file.rb')
    File.write(path, source)
    config = RuboCop::Config.new
    cop = RuboCop::Cop::Elegant::NoComments.new(config)
    commissioner = RuboCop::Cop::Commissioner.new([cop], [], raise_error: true)
    processed = RuboCop::ProcessedSource.new(source, Float(RUBY_VERSION[/[0-9]+.[0-9]+/]), path)
    result = commissioner.investigate(processed)
    result.offenses
  end
end
