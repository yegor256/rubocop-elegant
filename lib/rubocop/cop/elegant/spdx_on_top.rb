# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Requires the SPDX header to sit above the code. The header is the
# license declaration of the file, and REUSE keeps it in the first
# few lines so that scanners, editors and reviewers read the license
# without parsing past unrelated code. Only blank lines and comments
# may precede it: a shebang, a magic comment, a RuboCop directive.
# A file that carries no SPDX comment at all is left alone, because
# checking that the tags exist is the job of +reuse lint+ and not of
# this plugin. Only the first SPDX comment counts, so the tags of a
# multi-line header may be split by nothing but comments.
class RuboCop::Cop::Elegant::SpdxOnTop < RuboCop::Cop::Base
  MSG = 'SPDX header must be above the code, but this line comes before it'
  public_constant :MSG

  def on_new_investigation
    header = spdx
    return if header.nil?
    line = intruder(header.location.line)
    return if line.nil?
    add_offense(processed_source.buffer.line_range(line))
  end

  private

  def spdx
    processed_source.comments.find { |comment| comment.text.match?(/^#\s*SPDX-/) }
  end

  def intruder(stop)
    (1...stop).find { |idx| code?(processed_source.lines[idx - 1]) }
  end

  def code?(line)
    text = line.strip
    !text.empty? && !text.start_with?('#')
  end
end
