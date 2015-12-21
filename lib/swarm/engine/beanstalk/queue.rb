require "beaneater"
require_relative "job"

module Swarm
  module Engine
    module Beanstalk
      class Queue < Swarm::Engine::Queue
        attr_reader :address, :tube, :worker

        def initialize(name:, address: "localhost:11300", worker: nil)
          @name = name
          @address = address
          @beaneater = Beaneater.new(@address)
          @tube = @beaneater.tubes[@name]
          @worker = worker
        end

        def prepare_for_work(worker)
          self.class.new(:name => name, :address => address, worker: worker)
        end

        def add_job(data)
          Job.new(tube.put(data.to_json))
        end

        def reserve_job(worker)
          Job.new(tube.reserve)
        rescue Beaneater::NotFoundError, Beaneater::TimedOutError, Beaneater::JobNotReserved
          raise JobReservationFailed
        end

        def worker_count
          tube.stats.current_watching
        end

        def clear
          tube.clear
        end

        def idle?
          tube.peek(:ready).nil?
        end
      end
    end
  end
end