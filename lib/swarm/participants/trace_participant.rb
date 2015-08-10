require_relative "../participant"

module Swarm
  class TraceParticipant < Participant
    def work
      traced = workitem["traced"] || []
      traced += [arguments.keys.first]
      expression.workitem = workitem.merge("traced" => traced)
      hive.trace(arguments.keys.first)
      expression.reply
    end
  end
end
