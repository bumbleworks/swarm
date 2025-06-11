# frozen_string_literal: true

RSpec.describe Swarm::Engine::Job do
  subject { described_class.new }

  it_behaves_like "an interface with required implementations",
                  {
                    to_h: 0,
                    reserved?: 0,
                    bury: 0,
                    release: 0,
                    delete: 0,
                    exists?: 0
                  }
end
