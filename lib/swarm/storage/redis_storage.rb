require "redis"
require_relative "key_value_storage"

module Swarm
  module Storage
    class RedisStorage < KeyValueStorage
      def ids_for_type(type)
        store.keys("#{type}:*").map { |key| key.gsub(regex_for_type(type), '\1') }
      end

      def delete(key)
        store.del(key)
      end

      def truncate
        store.flushdb
      end
    end
  end
end