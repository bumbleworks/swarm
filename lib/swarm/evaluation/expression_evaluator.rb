require_relative "workitem_context"

module Swarm
  class ExpressionEvaluator
    extend Forwardable

    attr_reader :expression
    def_delegators :expression, :workitem, :arguments

    def initialize(expression)
      @expression = expression
    end

    def workitem_context
      @workitem_context ||= WorkitemContext.new(workitem)
    end

    def eval(string)
      workitem_context.instance_eval(string)
    end

    def all_conditions_met?
      conditions.all? { |type, exp|
        check_condition(type, exp)
      }
    end

    def check_condition(type, exp)
      unless ["if", "unless"].include?(type)
        raise ArgumentError.new("Not a conditional")
      end
      result = eval(exp)
      type == "if" ? result : !result
    end

    def conditions
      Swarm::Support.slice(arguments, "if", "unless")
    end
  end
end
