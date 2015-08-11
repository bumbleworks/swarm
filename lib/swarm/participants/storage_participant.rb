require_relative "../participant"

module Swarm
  class StorageParticipant < Participant
    def work
      StoredWorkitem.create({
        :hive => hive,
        :expression_id => expression.id
      })
    end
  end
end
