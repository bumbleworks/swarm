module Swarm
  class Process < HiveDweller
    set_columns :process_definition_id, :workitem, :root_expression_id
    many_to_one :process_definition, :class_name => "Swarm::ProcessDefinition"

    def launch
      hive.queue('launch', self)
      self
    end

    def _launch
      root_expression = SequenceExpression.create(
        :hive => hive,
        :parent_id => id,
        :position => 0,
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
      root_expression && root_expression.finished?
    end

    def node_at_position(position)
      raise ArgumentError unless position == 0
      process_definition.tree
    end

    def move_on_from(expression)
      self.workitem = expression.workitem
    end
  end
end