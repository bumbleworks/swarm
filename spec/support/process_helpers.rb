module ProcessHelpers
  def storage
    @storage ||= Swarm::Storage.new({})
  end

  def work_queue
    @work_queue ||= Swarm::Engine::WorkQueue.new(:name => "swarm-test-queue", :address => "localhost:11300")
  end

  def hive
    @hive ||= Swarm::Hive.new(:storage => storage, :work_queue => work_queue)
  end

  def wait_until(timeout: 5)
    Swarm::Support.wait_until(timeout: timeout, &Proc.new)
  end
end
