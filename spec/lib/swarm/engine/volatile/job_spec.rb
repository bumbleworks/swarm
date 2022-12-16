RSpec.describe Swarm::Engine::Volatile::Job do
  let(:queue) { Swarm::Engine::Volatile::Queue.new(name: "a queue") }
  let(:data) { { "foo" => "bar" } }
  subject { described_class.new(queue: queue, data: data) }

  describe ".new" do
    it "sets id to random uuid" do
      allow(SecureRandom).to receive(:uuid).
        and_return("a secret universe number!")
      expect(subject.id).to eq("a secret universe number!")
    end
  end

  describe "#to_h" do
    it "returns data with symbolized keys" do
      expect(subject.to_h).to eq(foo: "bar")
    end
  end

  describe "#==" do
    it "returns false if other is not a job" do
      other = double("SomethingElse", id: subject.id)
      expect(subject).not_to eq(other)
    end

    it "returns false if other has different id" do
      other = described_class.new(queue: queue, data: data)
      allow(other).to receive(:id).and_return("some other googat")
      expect(subject).not_to eq(other)
    end

    it "returns true if other has same id" do
      other = described_class.new(queue: queue, data: data)
      allow(other).to receive(:id).and_return(subject.id)
      expect(subject).to eq(other)
    end
  end

  describe "#reserve!" do
    it "raises exception if job already reserved by other client" do
      allow(subject).to receive(:reserved_by).and_return("horse")
      expect {
        subject.reserve!("not horse")
      }.to raise_error(described_class::AlreadyReservedError)
    end

    it "changes reservation to given client" do
      subject.reserve!("horse")
      expect(subject.reserved_by).to eq("horse")
    end

    it "does nothing if already reserved by given client" do
      allow(subject).to receive(:reserved_by).and_return("horse")
      subject.reserve!("horse")
      expect(subject.reserved_by).to eq("horse")
    end
  end

  describe "#reserved?" do
    it "returns true if reserved_by is set" do
      allow(subject).to receive(:reserved_by).and_return("horse")
      expect(subject.reserved?).to eq(true)
    end

    it "returns false if reserved_by is not set" do
      allow(subject).to receive(:reserved_by).and_return(nil)
      expect(subject.reserved?).to eq(false)
    end
  end

  describe "#bury" do
    it "sets buried attribute to true" do
      expect(subject.buried).to eq(false)
      subject.bury
      expect(subject.buried).to eq(true)
    end
  end

  describe "#available?" do
    it "returns true if not reserved and not buried" do
      expect(subject).to be_available
    end

    it "returns false if reserved" do
      subject.reserve!(:horse)
      expect(subject).not_to be_available
    end

    it "returns false if buried" do
      subject.bury
      expect(subject).not_to be_available
    end
  end

  describe "#release" do
    it "sets reserved_by attribute to nil" do
      subject.reserve!("horse")
      subject.release
      expect(subject.reserved_by).to eq(nil)
    end
  end

  describe "#delete" do
    it "deletes self from queue" do
      expect(subject.queue).to receive(:delete_job).with(subject)
      subject.delete
    end
  end

  describe "#exists?" do
    it "returns true if queue has self in job list" do
      allow(queue).to receive(:has_job?).with(subject).and_return(true)
      expect(subject.exists?).to eq(true)
    end

    it "returns false if queue does not have self in job list" do
      allow(queue).to receive(:has_job?).with(subject).and_return(false)
      expect(subject.exists?).to eq(false)
    end
  end
end
