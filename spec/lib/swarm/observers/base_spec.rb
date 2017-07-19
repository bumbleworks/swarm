require "swarm/observers/base"

RSpec.describe Swarm::Observers::Base do
  let(:command) { Swarm::Engine::Worker::Command.new(action: "brog", metadata: { foo: "ber" }) }
  subject { described_class.new(command) }

  describe "#action" do
    it "delegates to command" do
      expect(subject.action).to eq("brog")
    end
  end

  describe "#metadata" do
    it "delegates to command" do
      expect(subject.metadata).to eq({ foo: "ber" })
    end
  end

  describe "#object" do
    it "delegates to command" do
      allow(command).to receive(:object).and_return(:a_copper_robber)
      expect(subject.object).to eq(:a_copper_robber)
    end
  end

  describe "#before_action" do
    it "exists and does nothing" do
      expect { subject.before_action }.not_to raise_error
    end
  end

  describe "#after_action" do
    it "exists and does nothing" do
      expect { subject.after_action }.not_to raise_error
    end
  end
end
