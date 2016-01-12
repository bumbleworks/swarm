RSpec.describe Swarm::Storage::Hash do
  let(:hash) { { "foo:1" => "le foo", "foo:2" => "la foo", "bar:8" => "barp" } }
  subject { described_class.new(hash) }

  describe "#ids_for_type" do
    it "returns all ids for given type" do
      expect(subject.ids_for_type("foo")).to eq(["1", "2"])
      expect(subject.ids_for_type("bar")).to eq(["8"])
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
      expect(hash).to receive(:[]).with("foo:1").and_return("le foo")
      expect(subject["foo:1"]).to eq("magic")
    end
  end

  describe "#[]=" do
    it "sets key to serialized version of given value" do
      allow(subject).to receive(:serialize).with("tutu").and_return("synchronized_swimming")
      expect(hash).to receive(:[]=).with("bar:24", "synchronized_swimming")
      subject["bar:24"] = "tutu"
    end
  end

  describe "#truncate" do
    it "clears hash" do
      subject.truncate
      expect(subject.hash).to be_empty
    end
  end

  describe "#delete" do
    it "deletes key from hash" do
      subject.delete("foo:2")
      expect(subject.hash).to eq({ "foo:1" => "le foo", "bar:8" => "barp" })
    end
  end
end