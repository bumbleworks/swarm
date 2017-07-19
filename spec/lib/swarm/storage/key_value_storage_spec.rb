RSpec.describe Swarm::Storage::KeyValueStorage do
  let(:hash) { { "foo:1" => "le foo", "foo:2" => "la foo", "bar:8" => "barp" } }
  subject { described_class.new(hash) }

  it_behaves_like "an interface with required implementations",
    {
      all_of_type: 1,
      ids_for_type: 1,
      delete: 1,
      truncate: 0
    }

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

  describe "#add_association" do
    let(:owner) { double }
    let(:associated) { double(id: "15") }

    it "initializes association id array if missing" do
      allow(owner).to receive(:croutons_ids).
        and_return(nil)
      allow(owner).to receive(:croutons_ids=).with([]).and_return(the_ids_array = [])
      expect(
        subject.add_association("croutons", associated, owner: owner, class_name: "Salad::Crouton")
      ).to eq(associated)
      expect(the_ids_array).to eq(["15"])
    end

    it "adds id of associated to association ids" do
      the_ids_array = ["14"]
      allow(owner).to receive(:croutons_ids).
        and_return(the_ids_array)
      expect(
        subject.add_association("croutons", associated, owner: owner, class_name: "Salad::Crouton")
      ).to eq(associated)
      expect(the_ids_array).to eq(["14", "15"])
    end

    it "raises exception if owner does not respond to key" do
      expect {
        subject.add_association("croutons", associated, owner: owner, class_name: "Salad::Crouton")
      }.to raise_error(described_class::AssociationKeyMissingError, "croutons_ids")
    end
  end

  describe "#load_associations" do
    let(:owner) { double }

    it "returns associations" do
      allow(owner).to receive(:croutons_ids).
        and_return([1, 2])
      allow(subject).to receive(:[]).with("Crouton:1").and_return(:crouton1)
      allow(subject).to receive(:[]).with("Crouton:2").and_return(:crouton2)
      expect(
        subject.load_associations("croutons", owner: owner, class_name: "Salad::Crouton")
      ).to match_array([:crouton1, :crouton2])
    end

    it "returns empty array if associated objects missing" do
      allow(owner).to receive(:croutons_ids).
        and_return([1, 2])
      expect(
        subject.load_associations("croutons", owner: owner, class_name: "Salad::Crouton")
      ).to eq([])
    end

    it "returns empty array if no associated objects" do
      allow(owner).to receive(:croutons_ids).
        and_return(nil)
      expect(
        subject.load_associations("croutons", owner: owner, class_name: "Salad::Crouton")
      ).to eq([])
    end

    it "raises exception if owner does not respond to key" do
      expect {
        subject.load_associations("croutons", owner: owner, class_name: "Salad::Crouton")
      }.to raise_error(described_class::AssociationKeyMissingError, "croutons_ids")
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
end
