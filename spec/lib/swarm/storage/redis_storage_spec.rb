RSpec.describe Swarm::Storage::RedisStorage do
  let(:redis_db) { double(Redis) }
  subject { described_class.new(redis_db) }

  it "is a KeyValueStorage" do
    expect(subject).to be_a(Swarm::Storage::KeyValueStorage)
  end

  describe "#ids_for_type" do
    it "returns all ids for given type" do
      allow(redis_db).to receive(:is_a?).with(Redis).and_return(true)
      allow(redis_db).to receive(:keys).with("foo:*").and_return(["foo:3", "foo:4"])
      expect(subject.ids_for_type("foo")).to eq(["3", "4"])
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