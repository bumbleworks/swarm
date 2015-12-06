require "json"

module Swarm
  class ProcessDefinition < HiveDweller
    class NotYetPersistedError < StandardError; end

    set_columns :tree

    class << self
      def create_from_json(json, hive: Hive.default)
        create(:hive => hive, :tree => JSON.parse(json))
      end
    end

    def create_process(workitem)
      raise NotYetPersistedError unless id
      Process.create(
        :hive => hive,
        :process_definition_id => id,
        :workitem => workitem
      )
    end

    def launch_process(workitem)
      process = create_process(workitem)
      process.launch
    end
  end
end