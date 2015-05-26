module ProcessHelpers
  def storage
    @storage ||= Swarm::Storage.new({})
  end

  def work_queue
    @work_queue ||= Beaneater.new("localhost:11300").tubes["swarm-test-queue"]
  end

  def hive
    @hive ||= Swarm::Hive.new(:storage => storage, :work_queue => work_queue)
  end
end
