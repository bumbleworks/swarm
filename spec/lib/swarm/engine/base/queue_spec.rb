RSpec.describe Swarm::Engine::Queue do
  subject { described_class.new(name: "a queue") }

  it_behaves_like "an interface with required implementations",
    {
      prepare_for_work: 1,
      add_job: 1,
      reserve_job: 1,
      clear: 0,
      idle?: 0,
      worker_count: 0
    }
end