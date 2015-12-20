module Swarm
  module Engine
    module Volatile
      class Job < Swarm::Engine::Job
        attr_reader :channel, :data, :id, :reserved_by, :buried

        def initialize(channel:, data:)
          @channel = channel
          @data = data
          @id = SecureRandom.uuid
          @reserved_by = nil
          @buried = false
        end

        def to_h
          Swarm::Support.symbolize_keys(data)
        end

        def ==(other)
          other.is_a?(self.class) &&
            other.id == id
        end

        def reserve!(client)
          if reserved_by && reserved_by != client
            raise AlreadyReservedError
          end
          @reserved_by = client
        end

        def reserved?
          !reserved_by.nil?
        end

        def bury
          @buried = true
        end

        def available?
          !reserved? && !buried
        end

        def release
          @reserved_by = nil
        end

        def delete
          channel.delete_job(self)
        end

        def exists?
          channel.has_job?(self)
        end
      end
    end
  end
end