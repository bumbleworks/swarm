require_relative "storage"

module Swarm
  class Hive
    class MissingTypeError < StandardError; end

    attr_reader :storage, :work_queue

    def initialize(storage:, work_queue:)
      @storage = storage
      @work_queue = work_queue
    end

    def traced
      storage["trace"] ||= []
    end

    def trace(new_element)
      storage["trace"] = traced + [new_element]
    end

    def queue(command, object)
      @work_queue.add_job({
        :command => command,
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