# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

module RuboCop
  module Cop
    module Elegant
      class GoodVariableName < Base
        MSG = 'Variable name "%<name>s" does not match the required pattern'
        public_constant :MSG

        def on_lvasgn(node)
          check(node, node.children.first.to_s)
        end

        def on_ivasgn(node)
          check(node, node.children.first.to_s)
        end

        def on_cvasgn(node)
          check(node, node.children.first.to_s)
        end

        def on_gvasgn(node)
          check(node, node.children.first.to_s)
        end

        private

        def check(node, name)
          return if allowed?(name)
          return if match?(name)
          add_offense(node, message: format(MSG, name: name))
        end

        def match?(name)
          pattern.match?(name)
        end

        def allowed?(name)
          Array(cop_config['AllowedNames']).map(&:to_s).include?(name)
        end

        def pattern
          @pattern ||= Regexp.new(cop_config['Pattern'] || '^[a-z]+$')
        end
      end
    end
  end
end
