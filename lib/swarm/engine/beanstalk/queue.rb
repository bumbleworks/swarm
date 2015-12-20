require "beaneater"
require_relative "channel"

module Swarm
  module Engine
    module Beanstalk
      class Queue < Swarm::Engine::Queue
        attr_reader :address, :channel

        def initialize(name:, address: "localhost:11300")
          @name = name
          @address = address
          @beaneater = Beaneater.new(@address)
          @channel = Channel.new(tube: @beaneater.tubes[@name])
        end

        def clone
          @clone ||= self.class.new(:name => name, :address => address)
        end
      end
    end
  end
end