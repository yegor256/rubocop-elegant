# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

class RuboCop::Cop::Elegant::NoEmptyLinesInMethods < RuboCop::Cop::Base
  extend RuboCop::Cop::AutoCorrector

  MSG = 'Empty line inside method body is not allowed'
  public_constant :MSG

  def on_def(node)
    check(node)
  end

  def on_defs(node)
    check(node)
  end

  private

  def check(node)
    return if node.body.nil?
    lines = range(node)
    return if lines.nil?
    empty(lines).each { |num| register(num) }
  end

  def range(node)
    first = node.body.first_line
    last = node.body.last_line
    return if first == last
    (first..last)
  end

  def empty(lines)
    result = []
    lines.each do |num|
      result << num if processed_source.lines[num - 1].strip.empty?
    end
    result
  end

  def register(num)
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
