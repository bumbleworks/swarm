module Swarm
  module Storage
    class KeyValueStorage
      class AssociationKeyMissingError < StandardError; end

      attr_reader :store

      def initialize(store)
        @store = store
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

      def add_association(association_name, associated, owner:, class_name:, foreign_key: nil)
        key = :"#{association_name}_ids"
        if owner.respond_to?(key)
          ids = owner.send(key) || owner.send("#{key}=", [])
          ids << associated.id
          associated
        else
          raise AssociationKeyMissingError, key
        end
      end

      def load_associations(association_name, owner:, class_name:, foreign_key: nil)
        key = :"#{association_name}_ids"
        if owner.respond_to?(key)
          ids = owner.send(key) || []
          ids.map { |id|
            self["#{class_name.split("::").last}:#{id}"]
          }.compact
        else
          raise AssociationKeyMissingError, key
        end
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
