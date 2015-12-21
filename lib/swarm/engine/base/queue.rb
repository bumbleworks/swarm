require_relative "job"

module Swarm
  module Engine
    class Queue
      class JobReservationFailed < StandardError; end
      class JobNotFoundError < StandardError; end

      attr_reader :name

      def initialize(name:)
        @name = name
      end

      def prepare_for_work(worker)
        raise "Not implemented yet!"
      end

      def add_job(data)
        raise "Not implemented yet!"
      end

      def reserve_job(worker)
        raise "Not implemented yet!"
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

      def clear
        raise "Not implemented yet!"
      end

      def idle?
        raise "Not implemented yet!"
      end

      def worker_count
        raise "Not implemented yet!"
      end
    end
  end
end