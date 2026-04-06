# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

module RuboCop
  module Cop
    module Elegant
      class NoComments < Base
        extend AutoCorrector

        MSG = 'Comment is not allowed, unless it is SPDX, magic, or rubocop directive'

        def on_new_investigation
          processed_source.comments.each do |comment|
            register(comment) unless allowed?(comment)
          end
        end

        private

        def allowed?(comment)
          spdx?(comment) || magic?(comment) || rubocop?(comment)
        end

        def spdx?(comment)
          comment.text.match?(/^#\s*SPDX-/)
        end

        def magic?(comment)
          comment.text.match?(/^#\s*(frozen_string_literal|encoding|coding|warn_indent):/)
        end

        def rubocop?(comment)
          comment.text.match?(/^#\s*rubocop:(disable|enable|todo)\s/)
        end

        def register(comment)
          add_offense(comment) do |corrector|
            corrector.remove(removal(comment))
          end
        end

        def removal(comment)
          target = comment.source_range
          prefix = target.source_line[0, target.column]
          return fullrange(target) if prefix.strip.empty?
          prefixed(target, prefix)
        end

        def fullrange(target)
          start = target.begin_pos - target.column
          ending = target.end_pos
          ending += 1 if newline?(ending)
          target.with(begin_pos: start, end_pos: ending)
        end

        def prefixed(target, prefix)
          spaces = prefix.match(/\s*$/)[0]
          target.with(begin_pos: target.begin_pos - spaces.length, end_pos: target.end_pos)
        end

        def newline?(pos)
          processed_source.buffer.source[pos] == "\n"
        end
      end
    end
  end
end
