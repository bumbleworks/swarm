require_relative "job"

module Swarm
  module Engine
    class Channel
      class JobNotFoundError < StandardError; end

      def put(data)
        raise "Not implemented yet!"
      end

      def reserve(client)
        raise "Not implemented yet!"
      end

      def clear
        raise "Not implemented yet!"
      end

      def empty?
        raise "Not implemented yet!"
      end

      def worker_count
        raise "Not implemented yet!"
      end
    end
  end
end
