require "beaneater"

module Swarm
  module Engine
    class Worker
      attr_reader :hive, :queue

      def initialize(hive:)
        @hive = hive
        @queue = hive.work_queue.clone
      end

      def run!
        @running = true
        while running?
          process_next_job
        end
      end

      def process_next_job
        begin
          @current_job = queue.reserve_job
          @working = true
          work_on(@current_job)
          queue.delete_job(@current_job) if @current_job
        rescue WorkQueue::JobReservationFailed
          retry
        rescue StandardError
          queue.bury_job(@current_job) if @current_job
        ensure
          queue.clean_up_job(@current_job) if @current_job
          @working = false
          @current_job = nil
        end
      end

      def working?
        @working == true
      end

      def running?
        @running == true
      end

      def stop!
        @running = false
        @current_job = nil
      end

      def work_on(job)
        data = JSON.parse(job.body)
        command, metadata = data.values_at("command", "metadata")
        if command == "stop_worker"
          queue.remove_worker(self, :stop_job => job)
          stop!
        else
          run_command!(command, metadata)
        end
      end

      def run_command!(command, metadata)
        object = hive.fetch(metadata["type"], metadata["id"])
        object.send("_#{command}")
      end
    end
  end
end