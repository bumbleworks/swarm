module Swarm
  class Storage
    attr_reader :backend

    def initialize(backend)
      @backend = backend
    end

    def regex_for_type(type)
      /^#{type}\:(.*)/
    end

    def ids_for_type(type)
      keys = if backend.is_a?(Redis)
        backend.keys("#{type}:*")
      else
        backend.keys.select { |key| key.match(regex_for_type(type)) }
      end
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
      deserialize(backend[key])
    end

    def []=(key, value)
      backend[key] = serialize(value)
    end

    def delete(key)
      if backend.respond_to?(:del)
        backend.del(key)
      else
        backend.delete(key)
      end
    end

    def truncate
      if backend.respond_to?(:flushdb)
        backend.flushdb
      else
        backend.clear
      end
    end
  end
end