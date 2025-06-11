# frozen_string_literal: true

RSpec.describe Swarm::Storage::HashStorage do
  let(:hash) {
    {
      "foo:1" => {
        "type" => "foo",
        "data" => "le foo"
      },
      "foo:2" => {
        "type" => "pitifoo",
        "data" => "la foo"
      },
      "bar:8" => {
        "type" => "bar",
        "data" => "barp"
      }
    }
  }
  subject { described_class.new(hash) }

  it "is a KeyValueStorage" do
    expect(subject).to be_a(Swarm::Storage::KeyValueStorage)
  end

  describe "#ids_for_type" do
    it "returns all ids for given type" do
      expect(subject.ids_for_type("foo")).to eq(%w[1 2])
      expect(subject.ids_for_type("bar")).to eq(["8"])
    end
  end

  describe "#all_of_type" do
    it "returns all values for given type" do
      expect(subject.all_of_type("foo")).to eq(
        hash.values_at("foo:1", "foo:2")
      )
      expect(subject.all_of_type("bar")).to eq(
        hash.values_at("bar:8")
      )
    end

    it "excludes subtypes if constrained" do
      expect(subject.all_of_type("foo", subtypes: false)).to eq(
        hash.values_at("foo:1")
      )
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
      expect(subject.store.keys).to eq(["foo:1", "bar:8"])
    end
  end
end
