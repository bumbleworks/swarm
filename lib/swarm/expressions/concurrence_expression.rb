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
      method_from_args = arguments["combine_arrays"]
      return "uniq" unless method_from_args
      if ["uniq", "concat", "override"].include?(method_from_args.to_s)
        method_from_args.to_s
      else
        raise ArgumentError, "unknown array combination method"
      end
    end
  end
end