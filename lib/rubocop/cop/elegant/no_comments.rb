# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

module RuboCop
  module Cop
    module Elegant
      # Cop that disallows comments in source code.
      # Only SPDX license comments (lines starting with "# SPDX-") are allowed.
      #
      # @example
      #   # bad
      #   # This is a regular comment
      #   def foo; end
      #
      #   # good
      #   # SPDX-License-Identifier: MIT
      #   # SPDX-FileCopyrightText: Copyright (c) 2019-2026 Author
      #   def foo; end
      #
      # Author:: Yegor Bugayenko (yegor256@gmail.com)
      # Copyright:: Copyright (c) 2019-2026 Yegor Bugayenko
      # License:: MIT
      class NoComments < Base
        MSG = 'Comment is not allowed, unless it is SPDX'

        def on_new_investigation
          processed_source.comments.each do |comment|
            register(comment) unless spdx?(comment)
          end
        end

        private

        def spdx?(comment)
          comment.text.match?(/^#\s*SPDX-/)
        end

        def register(comment)
          add_offense(comment)
        end
      end
    end
  end
end
