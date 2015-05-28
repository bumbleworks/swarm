require "beaneater"

module Swarm
  class WorkQueue
    attr_reader :beaneater, :name

    def initialize(name:, address: "localhost:11300")
      @name = name
      @address = address
      @beaneater = Beaneater.new(@address)
      @tube = @beaneater.tubes[@name]
    end

    def add_job(hsh)
      @tube.put(hsh.to_json)
    end

    def clear
      @tube.clear
    end

    def clone
      self.class.new(:name => @name, :address => @address)
    end

    def worker_count
      @tube.stats.current_watching
    end
  end
end
