require_relative "channel"

module Swarm
  module Engine
    module Volatile
      class Queue < Swarm::Engine::Queue
        attr_reader :channel

        def initialize(name:)
          @name = name
          @channel = Channel.find_or_create(name)
          @channel.add_worker(self)
        end
      end
    end
  end
end