require_relative "branch_expression"

module Swarm
  class ConditionalExpression < BranchExpression
    alias_method :original_tree, :tree

    def work
      if tree.empty?
        reply
      else
        kick_off_children([0])
      end
    end

    def move_on_from(child)
      self.workitem = child.workitem
      reply
    end

    def tree
      @tree ||= select_branch || []
    end

    def select_branch
      if branch_condition_met?
        original_tree["true"]
      else
        original_tree["false"]
      end
    end

    def branch_condition_met?
      evaluator.check_condition(command, arguments["condition"])
    end
  end
end
