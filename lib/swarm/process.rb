# frozen_string_literal: true

require "timeout"

module Swarm
  class Process < HiveDweller
    set_columns :process_definition_id, :workitem, :root_expression_id, :parent_expression_id
    many_to_one :process_definition, class_name: "Swarm::ProcessDefinition"
    many_to_one :parent_expression, class_name: "Swarm::Expression"
    many_to_one :root_expression, class_name: "Swarm::Expression"
    one_to_many :expressions, class_name: "Swarm::Expression"

    def wait_until_finished(timeout: 5)
      Swarm::Support.wait_until(timeout: timeout) { finished? }
    end

    def launch
      hive.queue('launch', self)
      self
    end

    def _launch
      new_expression = SequenceExpression.create(
        hive: hive,
        parent_id: id,
        position: [0],
        workitem: workitem,
        process_id: id
      )
      new_expression.apply
      self.root_expression_id = new_expression.id
      save
    end

    def finished?
      reload!
      root_expression&.replied?
    end

    def node_at_position(position)
      raise ArgumentError unless position == 0

      process_definition.tree
    end

    def move_on_from(expression)
      self.workitem = expression.workitem
      save
      return unless parent_expression

      parent_expression.move_on_from(self)
    end

    def process_definition_name
      process_definition.name
    end
  end
end
