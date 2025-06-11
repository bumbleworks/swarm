# frozen_string_literal: true

require_relative "base"

module Swarm
  module Observers
    class Logger < Base
      attr_reader :initial_workitem

      def before_action
        return unless object

        @initial_workitem = object.workitem
      end

      def log_entry
        "[#{Time.now}]: #{action}; #{object_string}"
      end

      def after_action
        puts log_entry
      end

      def object_string
        return "No object" unless object

        object.reload!
        string = if object.is_a?(Swarm::Expression)
          "#{object.position}: #{object.command} #{object.arguments}"
        elsif object.is_a?(Swarm::Process)
          object.process_definition_name.to_s
        end
        if object.workitem != initial_workitem
          string += "; #{object.workitem}"
        end
        string
      end
    end
  end
end
