require "beaneater"

module Swarm
  class Worker
    attr_reader :hive

    def initialize(hive:)
      @hive = hive
      @beanstalk = hive.work_queue.client
      @tube_name = hive.work_queue.name
      @beanstalk.jobs.register(@tube_name) do |job|
        work_on(JSON.parse(job.body))
      end
    end

    def run!
      @beanstalk.jobs.process!
    end

    def stop!
      @beanstalk.jobs.stop!
    end

    def work_on(data)
      command = data["command"]
      metadata = data["metadata"]
      object = hive.fetch(metadata["type"], metadata["id"])
      object.send("_#{command}")
    rescue StandardError => e
      require 'pry'; binding.pry
      raise
    end
  end
end