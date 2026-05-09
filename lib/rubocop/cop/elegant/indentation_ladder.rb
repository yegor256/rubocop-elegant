# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Enforces the "indentation ladder" rule: when a line is indented further
# to the right than the previous non-empty line, the extra indentation
# must be exactly two spaces. Larger jumps (or odd ones, such as a single
# space or three spaces) break the visual rhythm of the code and make
# nesting harder to follow. Lines that match the previous indentation, or
# de-indent by any amount, are not affected. Lines that belong to the
# body of a heredoc are ignored, because their whitespace is part of the
# literal value rather than program structure.
class RuboCop::Cop::Elegant::IndentationLadder < RuboCop::Cop::Base
  MSG = 'Indentation step of %<step>d spaces is not allowed; use 2 spaces'
  public_constant :MSG

  def on_new_investigation
    super
    skip = heredocs
    prev = nil
    processed_source.lines.each_with_index do |line, idx|
      num = idx + 1
      next if skip.include?(num)
      next if line.strip.empty?
      indent = line[/\A */].length
      register(num, indent - prev) if prev && indent > prev && (indent - prev) != 2
      prev = indent
    end
  end

  private

  def heredocs
    result = []
    ast = processed_source.ast
    return result if ast.nil?
    ast.each_node(:str, :dstr, :xstr) do |node|
      next unless node.heredoc?
      body = node.loc.heredoc_body
      (body.first_line..body.last_line).each { |num| result << num }
    end
    result
  end

  def register(num, step)
    add_offense(processed_source.buffer.line_range(num), message: format(MSG, step: step))
  end
end
