RSpec.describe Swarm::Engine::Queue do
  subject { described_class.new(name: "a queue") }

  it_behaves_like "an interface with required implementations", { channel: 0 }
end