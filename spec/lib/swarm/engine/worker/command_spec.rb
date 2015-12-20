RSpec.describe Swarm::Engine::Worker::Command do
  let(:metadata) { { "foo" => "bar" } }
  let(:job_arguments) { { action: "fight", metadata: metadata } }
  subject { described_class.new(**job_arguments) }

  describe ".from_job" do
    it "parses action and metadata from queued job and instantiates Worker::Command" do
      job = double(:to_h => job_arguments)
      expect(described_class.from_job(job, hive: hive)).to eq(subject)
    end
  end

  describe "#to_hash" do
    it "returns hash of relevant command data" do
      allow(subject).to receive(:object).and_return(:the_object)
      expect(subject.to_hash).to eq({
        action: "fight",
        metadata: { :foo => "bar" },
        object: :the_object
      })
    end
  end

  describe "#run!" do
    it "sends given action to object" do
      hive_dweller = double
      allow(subject).to receive(:object).and_return(hive_dweller)
      expect(hive_dweller).to receive(:_fight)
      subject.run!
    end

    it "calls observer callbacks before and after" do
      foo_observer, bar_observer = double, double
      hive_dweller = double
      allow(subject).to receive(:object).and_return(hive_dweller)
      allow(subject).to receive(:observers).and_return([foo_observer, bar_observer])
      expect(foo_observer).to receive(:before_action).ordered
      expect(bar_observer).to receive(:before_action).ordered
      expect(hive_dweller).to receive(:_fight).ordered
      expect(foo_observer).to receive(:after_action).ordered
      expect(bar_observer).to receive(:after_action).ordered
      subject.run!
    end

    it "raises an exception if no object" do
      expect {
        subject.run!
      }.to raise_error(described_class::MissingObjectError)
    end
  end

  describe "#observers" do
    it "returns instances of each registered observer" do
      foo = double("FooObserver")
      bar = double("BarObserver")
      allow(foo).to receive(:new).with(subject).and_return(:foo_instance)
      allow(bar).to receive(:new).with(subject).and_return(:bar_instance)
      allow(hive).to receive(:registered_observers).and_return([foo, bar])
      expect(subject.observers).to eq([:foo_instance, :bar_instance])
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

  describe "#stop?" do
    it "returns true if action is 'stop_worker'" do
      allow(subject).to receive(:action).and_return("stop_worker")
      expect(subject.stop?).to eq(true)
    end

    it "returns false if action is not 'stop_worker'" do
      expect(subject.stop?).to eq(false)
    end
  end
end