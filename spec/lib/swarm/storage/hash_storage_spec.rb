RSpec.describe Swarm::Storage::HashStorage do
  let(:hash) { { "foo:1" => "le foo", "foo:2" => "la foo", "bar:8" => "barp" } }
  subject { described_class.new(hash) }

  it "is a KeyValueStorage" do
    expect(subject).to be_a(Swarm::Storage::KeyValueStorage)
  end

  describe "#ids_for_type" do
    it "returns all ids for given type" do
      expect(subject.ids_for_type("foo")).to eq(["1", "2"])
      expect(subject.ids_for_type("bar")).to eq(["8"])
    end
  end

  describe "#truncate" do
    it "clears hash" do
      subject.truncate
      expect(subject.store).to be_empty
    end
  end

  describe "#delete" do
    it "deletes key from hash" do
      subject.delete("foo:2")
      expect(subject.store).to eq({ "foo:1" => "le foo", "bar:8" => "barp" })
    end
  end
end