require_relative "../participant"

module Swarm
  class StorageParticipant < Participant
    def work
      StoredWorkitem.create({
        :hive => hive,
        :process_id => expression.process_id,
        :expression_id => expression.id,
        :workitem => workitem
      })
    end
  end
end
