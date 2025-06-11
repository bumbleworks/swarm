# frozen_string_literal: true

require "dentaku"

module Swarm
  class ExpressionEvaluator
    class UndefinedExpressionVariableError < StandardError; end
    class InvalidExpressionError < StandardError; end

    extend Forwardable

    attr_reader :expression

    def_delegators :expression, :workitem, :arguments

    def initialize(expression)
      @expression = expression
    end

    def evaluate_condition(string)
      Dentaku.evaluate!(string, workitem)
    rescue Dentaku::UnboundVariableError => e
      raise UndefinedExpressionVariableError, e
    rescue Dentaku::Error => e
      raise InvalidExpressionError, e
    end

    def all_conditions_met?
      conditions.all? { |type, condition|
        check_condition(type, condition)
      }
    end

    def check_condition(type, condition)
      unless %w[if unless].include?(type)
        raise ArgumentError, "Not a conditional"
      end

      result = evaluate_condition(condition)
      type == "if" ? result : !result
    end

    def conditions
      arguments.slice("if", "unless")
    end
  end
end
