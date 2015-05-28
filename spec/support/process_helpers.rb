module ProcessHelpers
  def storage
    @storage ||= Swarm::Storage.new({})
  end

  def work_queue
    @work_queue ||= Swarm::WorkQueue.new(:name => "swarm-test-queue", :address => "localhost:11300")
  end

  def hive
    @hive ||= Swarm::Hive.new(:storage => storage, :work_queue => work_queue)
  end
end
