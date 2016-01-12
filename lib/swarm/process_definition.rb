require "json"

module Swarm
  class ProcessDefinition < HiveDweller
    class NotYetPersistedError < StandardError; end

    set_columns :tree, :name, :version

    class << self
      def create_from_json(json, hive: Hive.default)
        create(**parse_json_definition(json).merge(:hive => hive))
      end

      def create_from_pollen(pollen, hive: Hive.default)
        json = Swarm::Pollen::Reader.new(pollen).to_json
        create_from_json(json, hive: hive)
      end

      def parse_json_definition(json)
        parsed = JSON.parse(json)
        if parsed.is_a?(Array)
          { :tree => parsed }
        else
          {
            :name => parsed["name"],
            :version => parsed["version"],
            :tree => parsed["definition"]
          }
        end
      end

      def find_by_name(name)
        detect { |definition| definition.name == name }
      end
    end

    def create_process(workitem:, **args)
      raise NotYetPersistedError unless id
      Process.create(
        args.merge({
          :workitem => workitem,
          :process_definition_id => id
        })
      )
    end

    def launch_process(workitem:, **args)
      process = create_process(workitem: workitem, **args)
      process.launch
    end
  end
end