require_relative "branch_expression"

module Swarm
  class SequenceExpression < BranchExpression
    def work
      kick_off_children([0])
    end

    def move_on_from(child)
      self.workitem = child.workitem
      kick_off_children([child.position + 1])
    rescue InvalidPositionError => e
      reply
    end
  end
end