module Swarm
  class StoredWorkitem < HiveDweller
    extend Forwardable

    def_delegators :expression, :node, :command, :arguments, :process_id, :workitem

    set_columns :expression_id
    many_to_one :expression, :class_name => "Swarm::Expression"
  end
end