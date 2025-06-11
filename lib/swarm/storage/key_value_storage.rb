# frozen_string_literal: true

module Swarm
  module Storage
    class KeyValueStorage
      class AssociationKeyMissingError < StandardError; end

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
        /^#{type}:(.*)/
      end

      def ids_for_type(_type)
        raise "Not implemented yet!"
      end

      def all_of_type(_type)
        raise "Not implemented yet!"
      end

      def add_association(association_name, associated, owner:, class_name:, foreign_key: nil)
        key = :"#{association_name}_ids"
        raise AssociationKeyMissingError, key unless owner.respond_to?(key)

        ids = owner.send(key) || owner.send("#{key}=", [])
        ids << associated.id
        associated
      end

      def load_associations(association_name, owner:, class_name:, foreign_key: nil)
        key = :"#{association_name}_ids"
        raise AssociationKeyMissingError, key unless owner.respond_to?(key)

        ids = owner.send(key) || []
        ids.map { |id|
          self["#{class_name.split("::").last}:#{id}"]
        }.compact
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

      def delete(_key)
        raise "Not implemented yet!"
      end

      def truncate
        raise "Not implemented yet!"
      end
    end
  end
end
