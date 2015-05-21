require 'simplecov'
SimpleCov.start

require "timecop"
# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

require './lib/swarm'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.include PathHelpers

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  config.before(:each) do
    storage = Swarm::Storage.new({})
    beanstalk = Beaneater.new("localhost:11300")
    work_queue = beanstalk.tubes["swarm-test-queue"]
    @hive = Swarm::Hive.new(:storage => storage, :work_queue => work_queue)
  end
end
