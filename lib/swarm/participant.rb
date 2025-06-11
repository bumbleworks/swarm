# frozen_string_literal: true

module Swarm
  class Participant
    attr_reader :hive, :expression

    def initialize(expression:, hive: Hive.default)
      @hive = hive
      @expression = expression
    end

    def workitem
      expression.workitem
    end

    def arguments
      expression.arguments
    end
  end
end
