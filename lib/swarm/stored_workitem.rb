module Swarm
  class StoredWorkitem < HiveDweller
    extend Forwardable

    def_delegators :expression, :node, :command, :arguments

    set_columns :process_id, :expression_id, :workitem
    many_to_one :expression, :class_name => "Swarm::Expression"
  end
end