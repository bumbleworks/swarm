require_relative "key_value_storage"

module Swarm
  module Storage
    class HashStorage < KeyValueStorage
      def ids_for_type(type)
        keys = store.keys.select { |key| key.match(regex_for_type(type)) }
        keys.map { |key| key.gsub(regex_for_type(type), '\1') }
      end

      def all_of_type(type, subtypes: true)
        store.select { |key, value|
          key.match(regex_for_type(type)) &&
            (subtypes || value["type"] == type)
        }.values
      end

      def delete(key)
        store.delete(key)
      end

      def truncate
        store.clear
      end
    end
  end
end