module Swarm
  module Engine
    module Beanstalk
      class Job < SimpleDelegator
        class AlreadyReservedError < StandardError; end

        def to_h
          Swarm::Support.symbolize_keys(JSON.parse(body))
        end
      end
    end
  end
end