# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'lint_roller'

class RuboCop::Elegant::Plugin < LintRoller::Plugin
  def about
    LintRoller::About.new(
      name: 'rubocop-elegant',
      version: RuboCop::Elegant::VERSION,
      homepage: 'https://github.com/yegor256/rubocop-elegant',
      description: 'Set of custom RuboCop cops for elegant Ruby coding'
    )
  end

  def supported?(context)
    context.engine == :rubocop
  end

  def rules(_context)
    LintRoller::Rules.new(
      type: :path,
      config_format: :rubocop,
      value: Pathname.new(__dir__).join('../../../config/default.yml')
    )
  end
end
