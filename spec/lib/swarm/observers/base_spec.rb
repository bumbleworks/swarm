require "swarm/observers/base"

RSpec.describe Swarm::Observers::Base do
  let(:worker_job) { Swarm::Engine::Worker::Job.new(hive: hive, command: "brog", metadata: "foober") }
  subject { described_class.new(worker_job) }

  describe "#command" do
    it "delegates to job" do
      expect(subject.command).to eq("brog")
    end
  end

  describe "#metadata" do
    it "delegates to job" do
      expect(subject.metadata).to eq("foober")
    end
  end

  describe "#object" do
    it "delegates to job" do
      allow(worker_job).to receive(:object).and_return(:a_copper_robber)
      expect(subject.object).to eq(:a_copper_robber)
    end
  end

  describe "#before_command" do
    it "exists and does nothing" do
      expect { subject.before_command }.not_to raise_error
    end
  end

  describe "#after_command" do
    it "exists and does nothing" do
      expect { subject.after_command }.not_to raise_error
    end
  end
end