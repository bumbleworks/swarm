RSpec.describe Swarm::Engine::Worker::Job do
  let(:metadata) { { "foo" => "bar" } }
  let(:job_arguments) { { command: "fight", metadata: metadata } }
  subject { described_class.new(hive: hive, **job_arguments) }

  describe ".from_queued_job" do
    it "parses command and metadata from queued job and instantiates Worker::Job" do
      job = double(:body => job_arguments.to_json)
      expect(described_class.from_queued_job(job, hive: hive)).to eq(subject)
    end
  end

  describe "#to_hash" do
    it "returns hash of relevant job data" do
      allow(subject).to receive(:object).and_return(:the_object)
      expect(subject.to_hash).to eq({
        command: "fight",
        metadata: { "foo" => "bar" },
        object: :the_object
      })
    end
  end

  describe "#run_command!" do
    it "sends given command to object" do
      hive_dweller = double
      allow(subject).to receive(:object).and_return(hive_dweller)
      expect(hive_dweller).to receive(:_fight)
      subject.run_command!
    end

    it "raises an exception if no object" do
      expect {
        subject.run_command!
      }.to raise_error(described_class::MissingObjectError)
    end
  end

  describe "#object" do
    context "without object lookup metadata" do
      it "returns nil" do
        expect(subject.object).to be_nil
      end
    end

    context "with object lookup metadata" do
      let(:metadata) { { "type" => "bear", "id" => 123 } }

      it "fetches object from hive" do
        allow(hive).to receive(:fetch).with("bear", 123).and_return("a bear")
        expect(subject.object).to eq("a bear")
      end
    end
  end

  describe "#stop_job?" do
    it "returns true if command is 'stop_worker'" do
      allow(subject).to receive(:command).and_return("stop_worker")
      expect(subject.stop_job?).to eq(true)
    end

    it "returns false if command is not 'stop_worker'" do
      expect(subject.stop_job?).to eq(false)
    end
  end
end