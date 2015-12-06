module Swarm
  module Engine
    class Worker
      class Job
        class MissingObjectError < StandardError; end

        class << self
          def from_queued_job(work_queue_job, hive: Hive.default)
            data = JSON.parse(work_queue_job.body)
            command, metadata = data.values_at("command", "metadata")
            new(command: command, metadata: metadata, hive: hive)
          end
        end

        attr_reader :command, :metadata, :hive

        def initialize(hive: Hive.default, command:, metadata:)
          @hive = hive
          @command = command
          @metadata = metadata
        end

        def run_command!
          raise MissingObjectError if object.nil?
          observers.each(&:before_command)
          object.send("_#{command}")
          observers.each(&:after_command)
        end

        def observers
          @observers ||= hive.registered_observers.map { |observer_class|
            observer_class.new(self)
          }
        end

        def object
          @object ||= begin
            return nil unless metadata["type"] && metadata["id"]
            hive.fetch(metadata["type"], metadata["id"])
          end
        end

        def stop_job?
          command == "stop_worker"
        end

        def to_hash
          {
            command: command,
            metadata: metadata,
            object: object
          }
        end

        def ==(other)
          other.is_a?(self.class) && other.to_hash == to_hash
        end
      end
    end
  end
end
