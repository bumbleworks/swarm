module Swarm
  module Storage
    class KeyValueStorage
      attr_reader :store

      def initialize(store)
        @store = store
      end

      def trace
        self["trace"]
      end

      def trace=(traced)
        self["trace"] = traced
      end

      def regex_for_type(type)
        /^#{type}\:(.*)/
      end

      def ids_for_type(type)
        raise "Not implemented yet!"
      end

      def all_of_type(type)
        raise "Not implemented yet!"
      end

      def serialize(value)
        return nil if value.nil?
        value.to_json
      end

      def deserialize(value)
        return nil if value.nil?
        JSON.parse(value)
      end

      def [](key)
        deserialize(store[key])
      end

      def []=(key, value)
        store[key] = serialize(value)
      end

      def delete(key)
        raise "Not implemented yet!"
      end

      def truncate
        raise "Not implemented yet!"
      end
    end
  end
end
