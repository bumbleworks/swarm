module Swarm
  class TraceExpression < Expression
    def work
      traced = workitem["traced"] || []
      traced += [arguments.keys.first]
      self.workitem = workitem.merge("traced" => traced)
      hive.trace(arguments.keys.first)
      save
      reply
    end
  end
end
