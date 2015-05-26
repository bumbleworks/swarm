module Swarm
  class HiveDweller
    attr_reader :hive, :id

    def initialize(hive:, id: nil, **args)
      @hive = hive
      @id = id
      unknown_arguments = args.keys - self.class.columns
      unless unknown_arguments.empty?
        raise ArgumentError, "unknown keywords: #{unknown_arguments.join(', ')}"
      end
      args.each do |key, val|
        instance_variable_set(:"@#{key}", val)
      end
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
      @id ||= Swarm::Support.uuid_with_timestamp
      storage[storage_id] = to_hash
      self
    end

    def attributes
      self.class.columns.each_with_object({}) { |col_name, hsh|
        value = instance_variable_get(:"@#{col_name}")
        hsh[col_name.to_sym] = value
      }
    end

    def to_hash
      hsh = {
        :id => id,
        :type => self.class.name
      }
      hsh.merge(attributes)
    end

    def reload!
      hsh = hive.storage[storage_id]
      self.class.columns.each do |column|
        instance_variable_set(:"@#{column}", hsh[column.to_s])
      end
      self
    end

    class << self
      attr_reader :columns

      def set_columns(*args)
        attr_accessor *args
        @columns = (@columns || []) | args
      end

      def many_to_one(type, class_name: nil)
        klass = Swarm::Support.constantize("#{class_name || type}")
        define_method(type) do
          klass.fetch(self.send(:"#{type}_id"), :hive => hive)
        end
      end

      def create(*args)
        new(*args).save
      end

      def storage_type
        name.split("::").last
      end

      def storage_id_for_key(key)
        if key.match(/^#{storage_type}\:/)
          key
        else
          "#{storage_type}:#{key}"
        end
      end

      def fetch(key, hive:)
        hsh = hive.storage[storage_id_for_key(key)].dup
        hive.reify_from_hash(hsh)
      end

      def ids(hive:)
        hive.storage.ids_for_type(storage_type)
      end

      def all(hive:, subtypes: true)
        ids(hive: hive).map { |id|
          fetch(id, hive: hive)
        }.select { |object|
          if subtypes
            object.is_a?(self)
          else
            object.class == self
          end
        }
      end
    end
  end
end
