module Swarm
  module Observers
    class Base
      extend Forwardable

      def_delegators :command, :action, :metadata, :object
      attr_reader :command

      def initialize(command)
        @command = command
      end

      def before_action; end
      def after_action; end
    end
  end
end