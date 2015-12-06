require 'simplecov'
SimpleCov.start

require "timecop"
# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

require './lib/swarm'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.expose_dsl_globally = false
  config.include PathHelpers
  config.include ProcessHelpers

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  config.before(:suite) do
    Swarm::Hive.default = Swarm::Hive.new(
      :storage => Swarm::Storage.new({}),
      :work_queue => Swarm::Engine::WorkQueue.new(:name => "swarm-test-queue", :address => "localhost:11300")
    )
  end

  config.before(:each) do
    storage["trace"] = nil
    hive.registered_observers.clear
  end

  config.around(:each, :type => :process) do |example|
    hive.work_queue.clear
    hive.storage.truncate
    worker = Swarm::Engine::Worker.new
    @worker_thread = Thread.new {
      worker.run!
    }
    example.run
    hive.work_queue.add_job({:command => "stop_worker"})
  end
end
