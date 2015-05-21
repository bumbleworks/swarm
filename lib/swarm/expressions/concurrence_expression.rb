require_relative "branch_expression"

module Swarm
  class ConcurrenceExpression < BranchExpression
    def _apply
      set_milestone("applied_at")
      kick_off_children(tree.each_index.to_a)
    end

    def all_children_replied?
      children.count(&:replied_at) == tree.size
    end

    def move_on_from(child)
      self.workitem = Swarm::Support.deep_merge(workitem, child.workitem)
      save
      if all_children_replied?
        reply
      end
    end
  end
end