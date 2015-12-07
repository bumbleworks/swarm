require_relative "../participant"

module Swarm
  class TraceParticipant < Participant
    def work
      if text
        append_to_workitem_trace
        append_to_hive_trace
      end
      expression.reply
    end

    def text
      @text ||= arguments.fetch("text", nil)
    end

    def append_to_workitem_trace
      traced = workitem["traced"] || []
      traced << text
      expression.workitem = workitem.merge("traced" => traced)
    end

    def append_to_hive_trace
      hive.trace(text)
    end
  end
end
