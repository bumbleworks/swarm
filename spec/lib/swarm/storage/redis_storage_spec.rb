RSpec.describe Swarm::Storage::RedisStorage do
  let(:redis_db) { double(Redis) }
  subject { described_class.new(redis_db) }

  describe "#ids_for_type" do
    it "returns all ids for given type" do
      allow(redis_db).to receive(:is_a?).with(Redis).and_return(true)
      allow(redis_db).to receive(:keys).with("foo:*").and_return(["foo:3", "foo:4"])
      expect(subject.ids_for_type("foo")).to eq(["3", "4"])
    end
  end

  describe "#serialize" do
    it "returns jsonified value" do
      value = double(:to_json => "scuba_gear")
      expect(subject.serialize(value)).to eq("scuba_gear")
    end

    it "returns nil if value nil" do
      expect(subject.serialize(nil)).to be_nil
    end
  end

  describe "#deserialize" do
    it "returns value parsed as JSON" do
      allow(JSON).to receive(:parse).with("scuba_gear").and_return("poboy")
      expect(subject.deserialize("scuba_gear")).to eq("poboy")
    end

    it "returns nil if value nil" do
      expect(subject.deserialize(nil)).to be_nil
    end
  end

  describe "#[]" do
    it "returns deserialized version of value at key" do
      allow(subject).to receive(:deserialize).with("le foo").and_return("magic")
      expect(redis_db).to receive(:[]).with("foo:1").and_return("le foo")
      expect(subject["foo:1"]).to eq("magic")
    end
  end

  describe "#[]=" do
    it "sets key to serialized version of given value" do
      allow(subject).to receive(:serialize).with("tutu").and_return("synchronized_swimming")
      expect(redis_db).to receive(:[]=).with("bar:24", "synchronized_swimming")
      subject["bar:24"] = "tutu"
    end
  end

  describe "#truncate" do
    it "flushes Redis DB" do
      # this expectation also makes "respond_to?" return true
      expect(redis_db).to receive(:flushdb)
      subject.truncate
    end
  end

  describe "#delete" do
    it "deletes key from redis_db" do
      # this expectation also makes "respond_to?" return true
      expect(redis_db).to receive(:del).with("foo:2")
      subject.delete("foo:2")
    end
  end
end