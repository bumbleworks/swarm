require_relative "storage"

module Swarm
  class Hive
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
      @work_queue.put({
        :command => command,
        :metadata => object.to_hash
      }.to_json)
    end

    def fetch(klass, id)
      Swarm::Support.constantize(klass).fetch(id, hive: self)
    end

    def reify_from_hash(hsh)
      Support.symbolize_keys!(hsh)
      Swarm::Support.constantize(hsh.delete(:type)).new(
        hsh.merge(
          :hive => self
        )
      )
    end
  end
end