module Swarm
  module Storage
    class HashStorage
      attr_reader :hash

      def initialize(hash)
        @hash = hash
      end

      def regex_for_type(type)
        /^#{type}\:(.*)/
      end

      def ids_for_type(type)
        keys = hash.keys.select { |key| key.match(regex_for_type(type)) }
        keys.map { |key| key.gsub(regex_for_type(type), '\1') }
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
        deserialize(hash[key])
      end

      def []=(key, value)
        hash[key] = serialize(value)
      end

      def delete(key)
        hash.delete(key)
      end

      def truncate
        hash.clear
      end
    end
  end
end