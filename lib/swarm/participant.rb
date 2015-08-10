module Swarm
  class Participant
    attr_reader :hive, :expression

    def initialize(hive:, expression:)
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
