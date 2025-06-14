# frozen_string_literal: true

module Swarm
  class HiveDweller
    class MissingTypeError < StandardError; end
    class RecordNotFoundError < StandardError; end

    attr_reader :hive, :id

    def initialize(hive: Hive.default, **args)
      @hive = hive
      @changed_attributes = {}
      set_attributes(args, record_changes: false)
    end

    def new?
      id.nil?
    end

    def changed?
      !@changed_attributes.empty?
    end

    def set_attributes(args, record_changes: true)
      unknown_arguments = args.keys - self.class.columns
      unless unknown_arguments.empty?
        raise ArgumentError, "unknown keywords: #{unknown_arguments.join(', ')}"
      end

      args.each do |key, value|
        change_attribute(key, value, record: record_changes)
      end
    end

    def change_attribute(key, value, record: true)
      if record
        @changed_attributes[key] = [send(key), value]
      end
      instance_variable_set(:"@#{key}", value)
    end

    def ==(other)
      other.is_a?(self.class) && other.to_hash == to_hash
    end

    def storage_id
      self.class.storage_id_for_key(id)
    end

    def storage
      @hive.storage
    end

    def delete
      storage.delete(storage_id)
      self
    end

    def save
      if new? || changed?
        @id ||= Swarm::Support.uuid_with_timestamp
        storage[storage_id] = to_hash.merge(updated_at: Time.now)
        reload!
      end
      self
    end

    def attributes
      self.class.columns.each_with_object({}) { |col_name, hsh|
        hsh[col_name.to_sym] = send(:"#{col_name}")
      }
    end

    def to_hash
      hsh = {
        id: id,
        type: self.class.name
      }
      hsh.merge(attributes)
    end

    def reload!
      hsh = hive.storage[storage_id]
      self.class.columns.each do |column|
        instance_variable_set(:"@#{column}", hsh[column.to_s])
      end
      self.class.associations.each_key do |name|
        instance_variable_set(:"@#{name}", nil)
      end
      @changed_attributes = {}
      self
    end

    class << self
      include Enumerable

      attr_reader :columns, :associations

      def inherited(subclass)
        super
        subclass.instance_variable_set(:@columns, [])
        subclass.instance_variable_set(:@associations, {})
        subclass.set_columns :updated_at, :created_at
      end

      def set_columns(*args)
        args.each do |arg|
          define_setter(arg)
          define_getter(arg)
        end
        @columns |= args
      end

      def define_setter(arg)
        define_method("#{arg}=") do |value|
          change_attribute(arg, value)
        end
      end

      def define_getter(arg)
        define_method(arg) {
          val = instance_variable_get(:"@#{arg}")
          if /_at$/.match(arg) && val.is_a?(String)
            val = Time.parse(val)
          end
          val
        }
      end

      def one_to_many(association_name, class_name: nil, foreign_key: nil)
        define_method(association_name) do
          memo = instance_variable_get(:"@#{association_name}")
          memo || begin
            associations = hive.storage.load_associations(
              association_name, owner: self, class_name: class_name || association_name, foreign_key: foreign_key
            )
            entities = associations.map { |association| self.class.reify_from_hash(association, hive: hive) }
            instance_variable_set(:"@#{association_name}", entities)
          end
        end
        define_method(:"add_to_#{association_name}") do |associated|
          hive.storage.add_association(
            association_name, associated, owner: self, class_name: class_name || association_name, foreign_key: foreign_key
          )
        end
        @associations[association_name] = {
          type: :one_to_many, class_name: class_name || association_name, foreign_key: foreign_key
        }
      end

      def many_to_one(association_name, class_name: nil, key: nil)
        define_method(association_name) do
          memo = instance_variable_get(:"@#{association_name}")
          memo || begin
            key ||= :"#{association_name}_id"
            associated_id = send(key)
            return nil unless associated_id

            klass = Swarm::Support.constantize((class_name || association_name).to_s)
            instance_variable_set(:"@#{association_name}", klass.fetch(associated_id, hive: hive))
          end
        end
        @associations[association_name] = {
          type: :many_to_one, class_name: class_name || association_name, key: key
        }
      end

      def create(hive: Hive.default, **args)
        new(hive: hive, created_at: Time.now, **args).save
      end

      def storage_type
        name.split("::").last
      end

      def storage_id_for_key(key)
        if key.match(/^#{storage_type}:/)
          key
        else
          "#{storage_type}:#{key}"
        end
      end

      def new_from_storage(**args)
        id = args.delete(:id)
        new(**args).tap { |instance|
          instance.instance_variable_set(:@id, id)
        }
      end

      def fetch(key, hive: Hive.default)
        hsh = hive.storage[storage_id_for_key(key)].dup
        reify_from_hash(hsh, hive: hive)
      end

      def ids(hive: Hive.default)
        hive.storage.ids_for_type(storage_type)
      end

      def each(hive: Hive.default, subtypes: true)
        return to_enum(__method__, hive: hive, subtypes: subtypes) unless block_given?

        ids(hive: hive).each do |id|
          object = fetch(id, hive: hive)
          if (subtypes && object.is_a?(self)) || object.instance_of?(self)
            yield object
          end
        end
      end

      def all(hive: Hive.default, subtypes: true)
        hive.storage.all_of_type(storage_type, subtypes: subtypes).map { |hsh|
          reify_from_hash(hsh.dup, hive: hive)
        }
      end

      def reify_from_hash(hsh, hive: Hive.default)
        Support.symbolize_keys!(hsh)
        raise MissingTypeError, hsh.inspect unless hsh[:type]

        Swarm::Support.constantize(hsh.delete(:type)).new_from_storage(
          **hsh.merge(hive: hive)
        )
      end
    end
  end
end
