module Swarm
  class BranchExpression < Expression
    class InvalidPositionError < StandardError; end;

    def children
      (child_ids || []).map { |child_id|
        Expression.fetch(child_id, hive: hive)
      }
    end

    def kick_off_children(at_positions)
      at_positions.each do |at_position|
        add_and_apply_child(at_position)
      end
      save
    end

    def add_and_apply_child(at_position)
      new_child = add_child(at_position)
      new_child.apply
    end

    def add_child(at_position)
      raise InvalidPositionError unless tree[at_position]
      command = tree[at_position][0]
      klass = Swarm::Support.constantize("swarm/#{command}_expression")
      expression = klass.create(
        :hive => hive,
        :parent_id => id,
        :position => at_position,
        :workitem => workitem,
        :process_id => process_id
      ).save
      (self.child_ids ||= []) << expression.id
      expression
    end
  end
end