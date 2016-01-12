module Swarm
  module Storage
    class Redis
      attr_reader :redis_db

      def initialize(redis_db)
        @redis_db = redis_db
      end

      def regex_for_type(type)
        /^#{type}\:(.*)/
      end

      def ids_for_type(type)
        redis_db.keys("#{type}:*").map { |key| key.gsub(regex_for_type(type), '\1') }
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
        deserialize(redis_db[key])
      end

      def []=(key, value)
        redis_db[key] = serialize(value)
      end

      def delete(key)
        redis_db.del(key)
      end

      def truncate
        redis_db.flushdb
      end
    end
  end
end