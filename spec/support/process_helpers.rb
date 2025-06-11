# frozen_string_literal: true

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

  def wait_until(**args, &block)
    Swarm::Support.wait_until(**args, &block)
  end

  def wait_until_worker_idle
    wait_until(initial_delay: 0.1) {
      work_queue.idle? && @worker_thread.stop?
    }
  end
end
