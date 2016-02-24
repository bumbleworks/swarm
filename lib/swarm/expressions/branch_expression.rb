require_relative "../router"

module Swarm
  class BranchExpression < Expression
    class InvalidPositionError < StandardError; end;

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
      node = tree[at_position]
      raise InvalidPositionError unless node
      expression = create_child_expression(node: node, at_position: at_position)
      (self.children_ids ||= []) << expression.id
      expression
    end

    def create_child_expression(node:, at_position:)
      klass = Router.expression_class_for_node(node)
      expression = klass.create(
        :hive => hive,
        :parent_id => id,
        :position => position + [at_position],
        :workitem => workitem,
        :process_id => process_id
      )
    end
  end
end