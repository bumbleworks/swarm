# frozen_string_literal: true

module Swarm
  class ActivityExpression < Expression
    def work
      if command == "trace"
        TraceParticipant.new(hive: hive, expression: self).work
      else
        StorageParticipant.new(hive: hive, expression: self).work
      end
    end
  end
end
