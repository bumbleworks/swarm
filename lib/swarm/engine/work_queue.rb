require "beaneater"

module Swarm
  module Engine
    class WorkQueue
      class JobReservationFailed < StandardError; end

      attr_reader :tube, :name

      def initialize(name:, address: "localhost:11300")
        @name = name
        @address = address
        @beaneater = Beaneater.new(@address)
        @tube = @beaneater.tubes[@name]
      end

      def add_job(hsh)
        tube.put(hsh.to_json)
      end

      def reserve_job
        tube.reserve
      rescue Beaneater::JobNotReserved, Beaneater::NotFoundError, Beaneater::TimedOutError
        raise JobReservationFailed
      end

      def delete_job(job)
        job.delete
      end

      def bury_job(job)
        job.bury if job.exists?
      end

      def clean_up_job(job)
        job.bury if job.exists? && job.reserved?
      end

      def remove_worker(worker, stop_job:)
        if worker_count <= 1
          stop_job.delete
        else
          stop_job.release
        end
      end

      def worker_count
        tube.stats.current_watching
      end

      def clear
        tube.clear
      end

      def clone
        self.class.new(:name => @name, :address => @address)
      end
    end
  end
end