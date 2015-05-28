require "beaneater"

module Swarm
  class Worker
    attr_reader :hive

    def initialize(hive:)
      @hive = hive
      @work_queue = hive.work_queue
      @beaneater = @work_queue.client
      @beaneater.jobs.register(@work_queue.name) do |job|
        work_on(job)
      end
    end

    def run!
      @beaneater.jobs.process!(:reserve_timeout => 1)
    end

    def stop!(job)
      if @work_queue.stats.current_watching == 1
        job.delete
      else
        job.release(:delay => 1)
      end
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
        stop!(job)
      else
        run_command!(command, metadata)
      end
    end
  end
end