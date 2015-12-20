module Swarm
  module Engine
    class Job
      class AlreadyReservedError < StandardError; end

      def to_h
        raise "Not implemented yet!"
      end

      def reserved?
        raise "Not implemented yet!"
      end

      def bury
        raise "Not implemented yet!"
      end

      def release
        raise "Not implemented yet!"
      end

      def delete
        raise "Not implemented yet!"
      end

      def exists?
        raise "Not implemented yet!"
      end
    end
  end
end
