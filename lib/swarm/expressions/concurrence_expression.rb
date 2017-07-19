require_relative "branch_expression"

module Swarm
  class ConcurrenceExpression < BranchExpression
    def work
      kick_off_children(tree.each_index.to_a)
    end

    def replied_children
      children.select(&:replied_at)
    end

    def ready_to_proceed?
      required_replies = arguments.fetch("required_replies", nil)
      return all_children_replied? unless required_replies
      replied_children.count >= required_replies
    end

    def all_children_replied?
      replied_children.count == tree.size
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
      arguments.fetch("combine_arrays", "uniq")
    end
  end
end
