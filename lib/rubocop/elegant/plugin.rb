# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'lint_roller'

module RuboCop
  module Elegant
    # LintRoller plugin for rubocop-elegant.
    # Registers the gem with RuboCop and provides default configuration.
    #
    # Author:: Yegor Bugayenko (yegor256@gmail.com)
    # Copyright:: Copyright (c) 2019-2026 Yegor Bugayenko
    # License:: MIT
    class Plugin < LintRoller::Plugin
      def about
        LintRoller::About.new(
          name: 'rubocop-elegant',
          version: VERSION,
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
  end
end
