require_relative "channel"

module Swarm
  module Engine
    class Queue
      class JobReservationFailed < StandardError; end

      attr_reader :name

      def initialize(name:)
        @name = name
      end

      def channel
        raise "Not implemented yet!"
      end

      def add_job(hsh)
        channel.put(hsh)
      end

      def reserve_job
        channel.reserve(self)
      rescue Channel::JobNotFoundError, Job::AlreadyReservedError
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
        channel.worker_count
      end

      def clear
        channel.clear
      end

      def idle?
        channel.empty?
      end

      def clone
        @clone ||= self.class.new(:name => name)
      end
    end
  end
end