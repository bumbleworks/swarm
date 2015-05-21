module Swarm
  class BranchExpression < Expression
    def children
      (child_ids || []).map { |child_id|
        Expression.fetch(child_id, hive: hive)
      }
    end

    def kick_off_children(at_positions)
      at_positions.each do |position|
        new_child = add_child(position)
        new_child.apply
      end
      save
    end

    def add_child(at_position)
      raise InvalidPositionError unless tree[at_position]
      command = tree[at_position][0]
      expression = hive.reify_from_hash(
        :parent_id => id,
        :position => at_position,
        :workitem => workitem,
        :type => Swarm::Support.camelize("#{command}_expression"),
        :process_id => process_id
      ).save
      (self.child_ids ||= []) << expression.id
      expression
    end
  end
end