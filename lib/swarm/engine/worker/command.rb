module Swarm
  module Engine
    class Worker
      class Command
        class MissingObjectError < StandardError; end

        class << self
          def from_job(job, hive: Hive.default)
            data = job.to_h
            action, metadata = data.values_at(:action, :metadata)
            new(action: action, metadata: metadata, hive: hive)
          end
        end

        attr_reader :action, :metadata, :hive

        def initialize(hive: Hive.default, action:, metadata:)
          @hive = hive
          @action = action
          @metadata = Swarm::Support.symbolize_keys(metadata || {})
        end

        def run!
          raise MissingObjectError if object.nil?
          observers.each(&:before_action)
          object.send("_#{action}")
          observers.each(&:after_action)
        end

        def observers
          @observers ||= hive.registered_observers.map { |observer_class|
            observer_class.new(self)
          }
        end

        def object
          @object ||= begin
            return nil unless metadata[:type] && metadata[:id]
            hive.fetch(metadata[:type], metadata[:id])
          end
        end

        def stop?
          action == "stop_worker"
        end

        def to_hash
          {
            action: action,
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
