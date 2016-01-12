require_relative "storage"

module Swarm
  class Hive
    class MissingTypeError < StandardError; end
    class IllegalDefaultError < StandardError; end
    class NoDefaultSetError < StandardError; end

    class << self
      def default=(default)
        unless default.is_a?(self)
          raise IllegalDefaultError.new("Default must be a Swarm::Hive")
        end
        @default = default
      end

      def default
        unless @default
          raise NoDefaultSetError.new("No default Hive defined yet")
        end
        @default
      end
    end

    attr_reader :storage, :work_queue

    def initialize(storage:, work_queue:)
      @storage = storage
      @work_queue = work_queue
    end

    def registered_observers
      @registered_observers ||= []
    end

    def inspect
      "#<Swarm::Hive storage: #{storage_class}, work_queue: #{work_queue.name}>"
    end

    def storage_class
      storage.class.name.split('::').last
    end

    def traced
      storage["trace"] ||= []
    end

    def trace(new_element)
      storage["trace"] = traced + [new_element]
    end

    def queue(action, object)
      @work_queue.add_job({
        :action => action,
        :metadata => object.to_hash
      })
    end

    def fetch(klass, id)
      Swarm::Support.constantize(klass).fetch(id, hive: self)
    end

    def reify_from_hash(hsh)
      Support.symbolize_keys!(hsh)
      raise MissingTypeError.new(hsh.inspect) unless hsh[:type]
      Swarm::Support.constantize(hsh.delete(:type)).new_from_storage(
        hsh.merge(
          :hive => self
        )
      )
    end
  end
end