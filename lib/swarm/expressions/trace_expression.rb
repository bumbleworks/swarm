module Swarm
  class TraceExpression < Expression
    def _apply
      set_milestone("applied_at")
      workitem["traced"] ||= []
      workitem["traced"] << arguments.keys.first
      hive.trace(arguments.keys.first)
      save
      reply
    end
  end
end
