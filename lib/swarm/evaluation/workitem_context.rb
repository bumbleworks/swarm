module Swarm
  class WorkitemContext
    attr_reader :workitem

    def initialize(workitem)
      @workitem = Support.symbolize_keys(workitem)
    end

    def method_missing(method, *args)
      if workitem.has_key?(method)
        workitem.fetch(method, nil)
      else
        super
      end
    end
  end
end