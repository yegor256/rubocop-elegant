# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

module RuboCop
  module Cop
    module Elegant
      class NoEmptyLinesInBlocks < Base
        extend AutoCorrector

        MSG = 'Empty line inside block body is not allowed'
        public_constant :MSG

        def on_new_investigation
          super
          @reported = []
        end

        def on_block(node)
          check(node)
        end

        def on_numblock(node)
          check(node)
        end

        def on_if(node)
          check(node)
        end

        def on_while(node)
          check(node)
        end

        def on_until(node)
          check(node)
        end

        def on_for(node)
          check(node)
        end

        def on_case(node)
          check(node)
        end

        def on_case_match(node)
          check(node)
        end

        def on_kwbegin(node)
          check(node)
        end

        private

        def check(node)
          lines = range(node)
          return if lines.nil?
          empty(lines).each { |num| register(num) }
        end

        def range(node)
          first = node.first_line + 1
          last = node.last_line - 1
          return if first > last
          (first..last)
        end

        def empty(lines)
          result = []
          lines.each do |num|
            line = processed_source.lines[num - 1]
            result << num if line.strip.empty?
          end
          result
        end

        def register(num)
          return if @reported.include?(num)
          @reported << num
          target = processed_source.buffer.line_range(num)
          add_offense(target) do |corrector|
            corrector.remove(fullrange(target))
          end
        end

        def fullrange(target)
          ending = target.end_pos
          ending += 1 if processed_source.buffer.source[ending] == "\n"
          target.with(end_pos: ending)
        end
      end
    end
  end
end
