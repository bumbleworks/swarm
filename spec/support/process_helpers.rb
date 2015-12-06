module ProcessHelpers
  def storage
    @storage ||= hive.storage
  end

  def work_queue
    @work_queue ||= hive.work_queue
  end

  def hive
    @hive ||= Swarm::Hive.default
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
