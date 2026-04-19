# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'English'

Gem::Specification.new do |s|
  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to?(:required_rubygems_version=)
  s.required_ruby_version = '>=2.2'
  s.name = 'rubocop-elegant'
  s.version = '0.0.18'
  s.license = 'MIT'
  s.summary = 'Set of custom RuboCop cops for elegant Ruby coding'
  s.description =
    'RuboCop plugin enforcing elegant coding style: no comments (except SPDX and magic), no empty lines in methods'
  s.authors = ['Yegor Bugayenko']
  s.email = 'yegor256@gmail.com'
  s.homepage = 'https://github.com/yegor256/rubocop-elegant'
  s.files = `git ls-files | grep -v -E '^(test/|\\.|renovate)'`.split($RS)
  s.rdoc_options = ['--charset=UTF-8']
  s.extra_rdoc_files = ['README.md']
  s.metadata['rubygems_mfa_required'] = 'true'
  s.metadata['default_lint_roller_plugin'] = 'RuboCop::Elegant::Plugin'
  s.add_dependency('lint_roller', '~> 1.1')
  s.add_dependency('rubocop', '~> 1.75')
end
