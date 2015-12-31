require "timeout"

module Swarm
  class Process < HiveDweller
    set_columns :process_definition_id, :workitem, :root_expression_id, :parent_expression_id
    many_to_one :process_definition, :class_name => "Swarm::ProcessDefinition"
    many_to_one :parent_expression, :class_name => "Swarm::Expression"

    def wait_until_finished(timeout: 5)
      Swarm::Support.wait_until(timeout: timeout) { finished? }
    end

    def launch
      hive.queue('launch', self)
      self
    end

    def _launch
      root_expression = SequenceExpression.create(
        :hive => hive,
        :parent_id => id,
        :position => [0],
        :workitem => workitem,
        :process_id => id
      )
      root_expression.apply
      self.root_expression_id = root_expression.id
      save
    end

    def root_expression
      @root_expression ||= begin
        reload! unless root_expression_id
        if root_expression_id
          Expression.fetch(root_expression_id, hive: hive)
        end
      end
    end

    def finished?
      root_expression && root_expression.replied?
    end

    def node_at_position(position)
      raise ArgumentError unless position == 0
      process_definition.tree
    end

    def move_on_from(expression)
      self.workitem = expression.workitem
      save
      if parent_expression
        parent_expression.move_on_from(self)
      end
    end
  end
end