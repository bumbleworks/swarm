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

  def wait_until(*args)
    Swarm::Support.wait_until(*args, &Proc.new)
  end

  def wait_until_worker_idle
    wait_until(initial_delay: 0.1) {
      work_queue.tube.peek(:ready).nil? && @worker_thread.stop?
    }
  end
end
