# frozen_string_literal: true

RSpec.describe Swarm::Hive do
  subject { hive }

  context "preserving default Hive" do
    around(:each) do |test|
      existing_default = described_class.default
      test.run
      described_class.default = existing_default
    end

    describe ".default=" do
      it "stores a default Hive instance" do
        dummy_hive = Swarm::Hive.new(storage: nil, work_queue: nil)
        described_class.default = dummy_hive
        expect(described_class.default).to eq(dummy_hive)
      end

      it "raises an exception if attempting to set non-hive default" do
        expect {
          described_class.default = "not a Hive"
        }.to raise_error(described_class::IllegalDefaultError)
      end
    end

    describe ".default" do
      it "raises an exception if no default set" do
        described_class.instance_variable_set(:"@default", nil)
        expect {
          described_class.default
        }.to raise_error(described_class::NoDefaultSetError)
      end
    end
  end

  describe "#fetch" do
    it "constantizes given type and delegates fetch to class" do
      klass_double = double
      allow(Swarm::Support).to receive(:constantize).with("Heads::AluminumHead").
        and_return(klass_double)
      expect(klass_double).to receive(:fetch).with("1234", hive: hive).and_return(:the_item)
      expect(subject.fetch("Heads::AluminumHead", "1234")).to eq(:the_item)
    end
  end

  describe "#inspect" do
    it "reveals storage class and work queue name" do
      expect(subject.inspect).to eq(
        "#<Swarm::Hive storage: #{subject.storage.class.name.split("::").last}, work_queue: swarm-test-queue>"
      )
    end
  end

  describe "#queue" do
    it "adds job to work queue" do
      expect(work_queue).to receive(:add_job).with({
        action: "do_something_to",
        metadata: "my_favorite_thing"
      })
      subject.queue("do_something_to", double(to_hash: "my_favorite_thing"))
    end
  end

  describe "#traced" do
    it "returns trace array from storage" do
      storage.trace = %w[pigs carbines]
      expect(subject.traced).to eq(%w[pigs carbines])
    end

    it "initializes trace to empty array if not previously set" do
      expect(storage.trace).to be_nil
      expect(subject.traced).to eq([])
      expect(storage.trace).to eq([])
    end
  end

  describe "#trace" do
    it "adds new element to trace array" do
      storage.trace = %w[pigs carbines]
      subject.trace("poplars")
      expect(subject.traced).to eq(%w[pigs carbines poplars])
    end

    it "initializes trace before adding element if trace empty" do
      expect(storage.trace).to be_nil
      subject.trace("hot dogs")
      expect(storage.trace).to eq(["hot dogs"])
    end
  end

  describe "#registered_observers" do
    it "defaults to empty array" do
      expect(subject.registered_observers).to eq([])
    end

    it "can be appended to" do
      subject.registered_observers << "hats"
      subject.registered_observers << "bumpers"
      expect(subject.registered_observers).to eq(%w[hats bumpers])
    end
  end
end
