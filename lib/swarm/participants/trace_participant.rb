require_relative "../participant"

module Swarm
  class TraceParticipant < Participant
    def work
      append_to_workitem_trace if text
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
  end
end
