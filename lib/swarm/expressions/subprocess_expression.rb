# frozen_string_literal: true

module Swarm
  class SubprocessExpression < Expression
    def work
      definition = ProcessDefinition.find_by_name(arguments.fetch("name", nil))
      raise Swarm::ProcessDefinition::RecordNotFoundError unless definition

      definition.launch_process(workitem: workitem, parent_expression_id: id)
    end

    def move_on_from(process)
      self.workitem = process.workitem
      reply
    end
  end
end
