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
            corrector.remove(removal_range(comment))
          end
        end

        def removal_range(comment)
          range = comment.source_range
          line_start = range.source_line[0, range.column]
          return range_with_line(range) if line_start.strip.empty?
          range_with_prefix(range, line_start)
        end

        def range_with_line(range)
          start_pos = range.begin_pos - range.column
          end_pos = range.end_pos
          end_pos += 1 if newline_after?(end_pos)
          range.with(begin_pos: start_pos, end_pos: end_pos)
        end

        def range_with_prefix(range, prefix)
          whitespace = prefix.match(/\s*$/)[0]
          range.with(begin_pos: range.begin_pos - whitespace.length, end_pos: range.end_pos)
        end

        def newline_after?(pos)
          processed_source.buffer.source[pos] == "\n"
        end
      end
    end
  end
end
