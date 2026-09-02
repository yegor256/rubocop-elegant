# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Enforces the "paired brackets" notation: every round, square, or curly
# bracket must either be paired with its matching counterpart on the same
# line, or end its own line (when opening) or start its own line (when
# closing). Brackets stranded in the middle of a multi-line expression
# are forbidden because they hide the structure of the code.
#
# Auto-correct relocates the offending bracket onto its own line: an
# opener that is not at end-of-line is followed by a newline and the
# opener-line indent plus two spaces; a closer that is not at
# start-of-line is preceded by a newline and the opener-line indent.
# The whitespace already sitting next to the bracket is consumed by
# the rewrite rather than left in place, so the moved code lands on
# the intended column instead of drifting right by that much.
# Surrounding indentation may still need a follow-up layout pass, but
# the brackets themselves end up paired.
#
# See https://www.yegor256.com/2014/10/23/paired-brackets-notation.html
class RuboCop::Cop::Elegant::PairedBrackets < RuboCop::Cop::Base
  extend RuboCop::Cop::AutoCorrector

  MSG = 'Bracket %<text>s must be paired on the same line, or start/end its line'
  public_constant :MSG

  OPENERS = %i[tLPAREN tLPAREN2 tLPAREN_ARG tLBRACK tLBRACK2 tLCURLY tLBRACE tLBRACE_ARG].freeze
  private_constant :OPENERS

  CLOSERS = %i[tRPAREN tRBRACK tRCURLY].freeze
  private_constant :CLOSERS

  BLANKS = [' ', "\t"].freeze
  private_constant :BLANKS

  def on_new_investigation
    super
    pair.each { |duo| check(duo) }
  end

  private

  def pair
    stack = []
    result = []
    processed_source.tokens.each do |tok|
      if OPENERS.include?(tok.type)
        stack << tok
      elsif CLOSERS.include?(tok.type) && !stack.empty?
        result << [stack.pop, tok]
      end
    end
    result
  end

  def check(duo)
    opener, closer = duo
    return if opener.line == closer.line
    indent = leading(opener)
    register(opener) { |corrector| corrector.replace(trailing(opener), "\n#{indent}  ") } unless ends?(opener)
    register(closer) { |corrector| corrector.replace(preceding(closer), "\n#{indent}") } unless starts?(closer)
  end

  def trailing(tok)
    text = processed_source.buffer.source
    stop = tok.pos.end_pos
    stop += 1 while BLANKS.include?(text[stop])
    tok.pos.end.resize(stop - tok.pos.end_pos)
  end

  def preceding(tok)
    text = processed_source.buffer.source
    from = tok.pos.begin_pos
    from -= 1 while from.positive? && BLANKS.include?(text[from - 1])
    tok.pos.begin.adjust(begin_pos: from - tok.pos.begin_pos)
  end

  def starts?(tok)
    processed_source.lines[tok.line - 1][0...tok.column].strip.empty?
  end

  def ends?(tok)
    after = processed_source.lines[tok.line - 1][(tok.column + tok.text.length)..-1].to_s.strip
    after.empty? || after.start_with?('#')
  end

  def leading(tok)
    processed_source.lines[tok.line - 1][/\A[ \t]*/]
  end

  def register(tok, &block)
    add_offense(tok.pos, message: format(MSG, text: tok.text), &block)
  end
end
