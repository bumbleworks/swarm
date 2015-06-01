require "beaneater"

module Swarm
  class Worker
    attr_reader :hive, :queue

    def initialize(hive:)
      @hive = hive
      @queue = hive.work_queue.clone
    end

    def run!
      @working = true
      while working?
        process_next_job
      end
    end

    def process_next_job
      begin
        @current_job = queue.reserve_job
        work_on(@current_job)
        queue.delete_job(@current_job) if @current_job
      rescue WorkQueue::JobReservationFailed
        retry
      rescue StandardError
        queue.bury_job(@current_job) if @current_job
      ensure
        queue.clean_up_job(@current_job) if @current_job
        @current_job = nil
      end
    end

    def working?
      @working == true
    end

    def stop!
      @working = false
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