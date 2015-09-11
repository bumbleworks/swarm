module Swarm
  module Observers
    class Base
      extend Forwardable

      def_delegators :job, :command, :metadata, :object
      attr_reader :job

      def initialize(job)
        @job = job
      end

      def before_command; end
      def after_command; end
    end
  end
end