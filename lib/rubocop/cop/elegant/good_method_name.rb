# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

class RuboCop::Cop::Elegant::GoodMethodName < RuboCop::Cop::Base
  MSG = 'Method name "%<name>s" does not match the required pattern'
  public_constant :MSG

  def on_def(node)
    check(node, node.method_name.to_s)
  end

  def on_defs(node)
    check(node, node.method_name.to_s)
  end

  private

  def check(node, name)
    return unless identifier?(name)
    return if allowed?(name)
    return if match?(name)
    add_offense(node, message: format(MSG, name: name))
  end

  def identifier?(name)
    /\A[a-zA-Z_]/.match?(name)
  end

  def match?(name)
    pattern.match?(name)
  end

  def allowed?(name)
    Array(cop_config['AllowedNames']).map(&:to_s).include?(name)
  end

  def pattern
    @pattern ||= Regexp.new(cop_config['Pattern'] || '^[a-z]+[!?]?$')
  end
end
