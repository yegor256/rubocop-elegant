# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

module RuboCop
  module Cop
    module Elegant
      class NoEmptyLinesInMethods < Base
        extend AutoCorrector

        MSG = 'Empty line inside method body is not allowed'

        def on_def(node)
          check(node)
        end

        def on_defs(node)
          check(node)
        end

        private

        def check(node)
          return if node.body.nil?
          body_range = body_range(node)
          return if body_range.nil?
          find_empty_lines(body_range).each do |line_range|
            register(line_range)
          end
        end

        def body_range(node)
          first_line = node.body.first_line
          last_line = node.body.last_line
          return nil if first_line == last_line
          (first_line..last_line)
        end

        def find_empty_lines(line_range)
          empty = []
          line_range.each do |line_num|
            line = processed_source.lines[line_num - 1]
            empty << line_num if line.strip.empty?
          end
          empty
        end

        def register(line_num)
          range = processed_source.buffer.line_range(line_num)
          add_offense(range) do |corrector|
            corrector.remove(line_with_newline(range))
          end
        end

        def line_with_newline(range)
          end_pos = range.end_pos
          end_pos += 1 if processed_source.buffer.source[end_pos] == "\n"
          range.with(end_pos: end_pos)
        end
      end
    end
  end
end
