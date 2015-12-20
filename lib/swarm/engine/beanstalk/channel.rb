require_relative "job"

module Swarm
  module Engine
    module Beanstalk
      class Channel < Swarm::Engine::Channel
        attr_reader :tube

        def initialize(tube:)
          @tube = tube
        end

        def put(data)
          Job.new(tube.put(data.to_json))
        end

        def reserve(client)
          Job.new(tube.reserve)
        rescue Beaneater::NotFoundError, Beaneater::TimedOutError
          raise JobNotFoundError
        rescue Beaneater::JobNotReserved
          raise Swarm::Engine::Job::AlreadyReservedError
        end

        def worker_count
          tube.stats.current_watching
        end

        def clear
          tube.clear
        end

        def empty?
          tube.peek(:ready).nil?
        end
      end
    end
  end
end