# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Enforces the "paired brackets" notation: every round, square, or curly
# bracket must either be paired with its matching counterpart on the same
# line, or end its own line (when opening) or start its own line (when
# closing). Brackets stranded in the middle of a multi-line expression
# are forbidden because they hide the structure of the code.
#
# See https://www.yegor256.com/2014/10/23/paired-brackets-notation.html
class RuboCop::Cop::Elegant::PairedBrackets < RuboCop::Cop::Base
  MSG = 'Bracket %<text>s must be paired on the same line, or start/end its line'
  public_constant :MSG

  OPENERS = %i[tLPAREN tLPAREN2 tLPAREN_ARG tLBRACK tLBRACK2 tLCURLY tLBRACE tLBRACE_ARG].freeze
  private_constant :OPENERS

  CLOSERS = %i[tRPAREN tRBRACK tRCURLY].freeze
  private_constant :CLOSERS

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
    register(opener) unless ends?(opener)
    register(closer) unless starts?(closer)
  end

  def starts?(tok)
    line = processed_source.lines[tok.line - 1]
    line[0...tok.column].strip.empty?
  end

  def ends?(tok)
    line = processed_source.lines[tok.line - 1]
    after = line[(tok.column + tok.text.length)..-1].to_s.strip
    after.empty? || after.start_with?('#')
  end

  def register(tok)
    add_offense(tok.pos, message: format(MSG, text: tok.text))
  end
end
