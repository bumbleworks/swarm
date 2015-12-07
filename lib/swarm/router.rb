module Swarm
  class Router
    class << self
      def expression_class_for_node(node)
        command = node[0]
        expression_type = case command
        when "if", "unless"
          "conditional"
        when "sequence", "concurrence"
          command
        else
          "activity"
        end
        Swarm::Support.constantize("swarm/#{expression_type}_expression")
      end
    end
  end
end
