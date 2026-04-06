# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

module RuboCop
  module Cop
    module Elegant
      class NoComments < Base
        extend AutoCorrector

        MSG = 'Comment is not allowed, unless it is SPDX, magic, or rubocop directive'
        public_constant :MSG

        def on_new_investigation
          processed_source.comments.each do |comment|
            register(comment) unless allowed?(comment)
          end
        end

        private

        def allowed?(comment)
          spdx?(comment) || magic?(comment) || rubocop?(comment) || (gemspec? && docblock?(comment))
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

        def gemspec?
          return @gemspec if defined?(@gemspec)
          path = processed_source.path
          return @gemspec = false if path.nil?
          dir = File.dirname(path)
          @gemspec = Dir.glob(File.join(dir, '*.gemspec')).any?
        end

        def docblock?(comment)
          line = comment.location.line
          successor = codeline(line)
          return false if successor.nil?
          definition?(successor)
        end

        def codeline(start)
          lines = processed_source.lines
          (start...lines.size).each do |idx|
            content = lines[idx]
            next if content.nil?
            stripped = content.strip
            next if stripped.empty? || stripped.start_with?('#')
            return idx + 1
          end
          nil
        end

        def definition?(line)
          ast = processed_source.ast
          return false if ast.nil?
          ast.each_node(:class, :module, :def, :defs) do |node|
            return true if node.location.line == line
          end
          false
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
