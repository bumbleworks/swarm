require_relative "evaluation/expression_evaluator"

module Swarm
  class Expression < HiveDweller
    class << self
      def storage_type
        "Expression"
      end

      def inherited(subclass)
        super
        subclass.set_columns *columns
      end
    end

    set_columns :parent_id, :position, :workitem, :child_ids, :milestones, :process_id
    many_to_one :process, :class_name => "Swarm::Process"

    def branch_position
      @branch_position ||= position.last
    end

    def evaluator
      @evaluator ||= Swarm::ExpressionEvaluator.new(self)
    end

    def meets_conditions?
      evaluator.all_conditions_met?
    end

    def root?
      process_id == parent_id
    end

    def parent
      if root?
        process
      else
        Expression.fetch(parent_id, hive: hive)
      end
    end

    def apply
      hive.queue('apply', self)
    end

    def reply
      save
      hive.queue('reply', self)
    end

    def _apply
      set_milestone("applied_at")
      meets_conditions? ? work : reply
      save
    end

    def _reply
      set_milestone("replied_at")
      save
      reply_to_parent
    end

    def reply_to_parent
      parent.move_on_from(self)
    end

    def replied_at
      get_milestone("replied_at")
    end

    def replied?
      reload!
      !!replied_at
    end

    def node
      @node ||= parent.node_at_position(branch_position)
    end

    def command
      node[0]
    end

    def arguments
      node[1]
    end

    def tree
      node[2]
    end

    def node_at_position(position)
      tree[position]
    end

  private

    def set_milestone(name, at: Time.now.to_i)
      self.milestones = (milestones || {}).merge(name => at)
    end

    def get_milestone(name)
      (milestones || {})[name]
    end
  end
end