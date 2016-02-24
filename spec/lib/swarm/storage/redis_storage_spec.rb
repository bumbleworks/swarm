RSpec.describe Swarm::Storage::RedisStorage do
  let(:redis_db) { double(Redis) }
  let(:data) {
    {
      "foo:1" => {
        "type" => "foo",
        "data" => "le foo"
      },
      "foo:2" => {
        "type" => "pitifoo",
        "data" => "la foo"
      }
    }
  }

  subject { described_class.new(redis_db) }

  it "is a KeyValueStorage" do
    expect(subject).to be_a(Swarm::Storage::KeyValueStorage)
  end

  describe "#ids_for_type" do
    it "returns all ids for given type" do
      allow(redis_db).to receive(:keys).with("foo:*").and_return(data.keys)
      expect(subject.ids_for_type("foo")).to eq(["1", "2"])
    end
  end

  describe "#all_of_type" do
    it "returns all values for given type" do
      allow(redis_db).to receive(:keys).with("foo:*").and_return(data.keys)
      allow(redis_db).to receive(:mapped_mget).with(*data.keys).
        and_return(data)
      expect(subject.all_of_type("foo")).to eq(data.values)
    end

    it "does not include subtypes if constrained" do
      allow(redis_db).to receive(:keys).with("foo:*").and_return(data.keys)
      allow(redis_db).to receive(:mapped_mget).with(*data.keys).
        and_return(data)
      expect(subject.all_of_type("foo", subtypes: false)).to eq(data.values_at("foo:1"))
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