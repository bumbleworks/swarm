require_relative "branch_expression"

module Swarm
  class ConcurrenceExpression < BranchExpression
    def work
      kick_off_children(tree.each_index.to_a)
    end

    def all_children_replied?
      children.count(&:replied_at) == tree.size
    end

    def move_on_from(child)
      merge_child_workitem(child)
      save
      if all_children_replied?
        reply
      end
    end

    def merge_child_workitem(child)
      self.workitem = Swarm::Support.deep_merge(
        workitem, child.workitem, :combine_arrays => array_combination_method
      )
    end

    def array_combination_method
      arguments["combine_arrays"] || "uniq"
    end
  end
end