RSpec.describe Swarm::Engine::Channel do
  subject { described_class.new }

  it_behaves_like "an interface with required implementations",
    {
      put: 1,
      reserve: 1,
      clear: 0,
      empty?: 0,
      worker_count: 0
    }
end