require_relative "worker/command"

module Swarm
  module Engine
    class Worker
      class NotRunningError < StandardError; end

      attr_reader :hive, :queue

      def initialize(hive: Hive.default)
        @hive = hive
      end

      def setup
        @queue = hive.work_queue.prepare_for_work(self)
      end

      def teardown
        @queue = nil
      end

      def run!
        setup
        @running = true
        while running?
          process_next_job
        end
        teardown
      end

      def process_next_job
        begin
          @current_job = queue.reserve_job(self)
          @working = true
          work_on(@current_job)
          queue.delete_job(@current_job) if @current_job
        rescue Queue::JobReservationFailed
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
        @running == true && queue
      end

      def stop!
        @running = false
        @current_job = nil
      end

      def work_on(queue_job)
        raise NotRunningError unless running?
        command = Command.from_job(queue_job, hive: hive)
        if command.stop?
          queue.remove_worker(self, stop_job: queue_job)
          stop!
        else
          command.run!
        end
      end
    end
  end
end
