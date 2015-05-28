require "beaneater"

module Swarm
  class Worker
    attr_reader :hive

    def initialize(hive:)
      @hive = hive
      @work_queue = hive.work_queue.clone
      @beaneater = @work_queue.beaneater
    end

    def register_processor
      @beaneater.jobs.register(@work_queue.name) do |job|
        work_on(job)
      end
    end

    def run!
      register_processor
      @beaneater.jobs.process!
    end

    def clean_up_stop_job(job)
      if @work_queue.worker_count == 1
        job.delete
      else
        job.release(:delay => 1)
      end
    end

    def stop!
      raise Beaneater::AbortProcessingError
    end

    def run_command!(command, metadata)
      object = hive.fetch(metadata["type"], metadata["id"])
      object.send("_#{command}")
    end

    def work_on(job)
      data = JSON.parse(job.body)
      command, metadata = data.values_at("command", "metadata")
      if command == "stop_worker"
        clean_up_stop_job(job)
        stop!
      else
        run_command!(command, metadata)
      end
    end
  end
end