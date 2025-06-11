# frozen_string_literal: true

require "redis"
require_relative "key_value_storage"

module Swarm
  module Storage
    class RedisStorage < KeyValueStorage
      def ids_for_type(type)
        store.keys("#{type}:*").map { |key| key.gsub(regex_for_type(type), '\1') }
      end

      def all_of_type(type, subtypes: true)
        hsh = store.mapped_mget(*store.keys("#{type}:*"))
        if subtypes
          hsh.values
        else
          hsh.select { |_key, value| value["type"] == type }.values
        end
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
