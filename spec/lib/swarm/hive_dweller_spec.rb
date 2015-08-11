RSpec.describe Swarm::HiveDweller do
  let(:test_class) {
    Class.new(described_class).tap { |klass|
      klass.set_columns :horse, :rabbits
    }
  }
  subject {
    test_class.new_from_storage({
      :hive => hive, :id => "1234", :horse => "fire", :rabbits => "earth"
    })
  }

  before(:each) do
    allow(test_class).to receive(:name).and_return("Heads::AluminumHead")
  end

  describe "#attributes" do
    it "returns values for all columns" do
      expect(subject.attributes).to eq(:horse => "fire", :rabbits => "earth")
    end

    it "returns nil for any attributes not set" do
      test_class.set_columns :alabama
      expect(subject.attributes).to eq(
        :horse => "fire", :rabbits => "earth", :alabama => nil
      )
    end
  end

  describe "#new?" do
    it "returns true for instance without id" do
      expect(test_class.new(:hive => hive).new?).to eq(true)
    end

    it "returns false for instance with id" do
      expect(subject.new?).to eq(false)
    end
  end

  describe "#changed?" do
    it "returns false if new" do
      expect(test_class.new(:hive => hive).changed?).to eq(false)
    end

    it "returns false if no columns have changed" do
      expect(subject.changed?).to eq(false)
    end

    it "returns true if columns have changed" do
      subject.horse = "pony"
      expect(subject.changed?).to eq(true)
    end
  end

  describe "#storage_id" do
    it "returns id plus storage type" do
      expect(subject.storage_id).to eq("AluminumHead:1234")
    end
  end

  describe "#save" do
    it "stores self in storage if change" do
      subject.horse = "pony"
      expect(hive.storage).to receive(:[]=).with("AluminumHead:1234", subject.to_hash)
      subject.save
    end

    it "generates id before saving if nonexistent" do
      allow(subject).to receive(:to_hash).and_return({ :foo => :bar })
      subject.instance_variable_set(:@id, nil)
      allow(Swarm::Support).to receive(:uuid_with_timestamp).
        and_return("123-345-567")
      subject.save
      expect(hive.storage["AluminumHead:123-345-567"]).to eq({ "foo" => "bar" })
    end

    it "saves if new" do
      new_object = test_class.new(:hive => hive)
      allow(Swarm::Support).to receive(:uuid_with_timestamp).
        and_return("9999")
      expect(hive.storage).to receive(:[]=).with("AluminumHead:9999", new_object.to_hash.merge(:id => "9999"))
      new_object.save
    end

    it "does nothing if no change and not new" do
      expect(hive.storage).not_to receive(:[]=)
      subject.save
    end
  end

  describe "#delete" do
    it "deletes self from storage and returns self" do
      expect(hive.storage).to receive(:delete).with("AluminumHead:1234")
      expect(subject.delete).to eq(subject)
    end
  end

  describe "#to_hash" do
    it "returns attributes with id and type merged in" do
      expect(subject.to_hash).to eq({
        :id => "1234",
        :type => "Heads::AluminumHead",
        :horse => "fire",
        :rabbits => "earth"
      })
    end
  end

  describe "#reload!" do
    it "re-retrieves hash from storage and populates columns" do
      hive.storage["AluminumHead:1234"] = subject.to_hash.merge(:horse => "snoot")
      expect(subject.horse).to eq("fire")
      subject.reload!
      expect(subject.horse).to eq("snoot")
    end

    it "resets changed? to false" do
      hive.storage["AluminumHead:1234"] = subject.to_hash
      subject.horse = "snoot"
      expect(subject).to be_changed
      subject.reload!
      expect(subject).not_to be_changed
    end

    it "clears associations" do
      association_class = double
      allow(association_class).to receive(:fetch).
        with("12345", :hive => hive).and_return(:the_object)
      allow(association_class).to receive(:fetch).
        with("67890", :hive => hive).and_return(:the_other_object)
      allow(Swarm::Support).to receive(:constantize).
        with("puppy").and_return(association_class)

      test_class.set_columns :puppy_id
      test_class.many_to_one :puppy

      hive.storage["AluminumHead:1234"] = subject.to_hash.merge(:puppy_id => "67890")
      subject.puppy_id = "12345"
      expect(subject.puppy).to eq(:the_object)
      subject.reload!
      expect(subject.puppy).to eq(:the_other_object)
    end
  end

  describe ".new" do
    it "returns a new instance with columns set" do
      instance = test_class.new(:hive => hive, :horse => "fire", :rabbits => "earth")
      expect(instance.attributes).to eq(:horse => "fire", :rabbits => "earth")
    end

    it "raises an ArgumentError if any arguments are not columns" do
      expect {
        test_class.new(:hive => hive, :horse => "fire", :lemons => "sweet")
      }.to raise_error(ArgumentError, "unknown keywords: lemons")
    end

    it "does not allow directly setting id" do
      expect {
        test_class.new(:hive => hive, :id => "secret_hack", :horse => "fire")
      }.to raise_error(ArgumentError, "unknown keywords: id")
    end
  end

  describe ".new_from_storage" do
    it "returns a new instance with id set" do
      instance = test_class.new_from_storage(:hive => hive, :id => "1234", :horse => "fire", :rabbits => "earth")
      expect(subject.attributes).to eq(:horse => "fire", :rabbits => "earth")
      expect(subject.id).to eq("1234")
    end
  end

  describe ".create" do
    it "instantiates a new object and immediately saves it" do
      new_object = double
      allow(test_class).to receive(:new).with(:the_args).and_return(new_object)
      expect(new_object).to receive(:save)
      test_class.create(:the_args)
    end
  end

  describe ".fetch" do
    it "retrieves hash from storage for given key and reifies" do
      allow(Swarm::Support).to receive(:constantize).with("Heads::AluminumHead").
        and_return(test_class)
      hive.storage["AluminumHead:1234"] = subject.to_hash
      expect(test_class.fetch("1234", :hive => hive)).to eq(subject)
    end

    it "raises exception if object in storage has no type" do
      bad_hash = subject.to_hash.tap { |hsh| hsh.delete(:type) }
      hive.storage["AluminumHead:1234"] = bad_hash
      expect {
        test_class.fetch("1234", :hive => hive)
      }.to raise_error(Swarm::Hive::MissingTypeError, bad_hash.inspect)
    end
  end

  describe ".storage_id_for_key" do
    it "returns given key if it already contains storage_type" do
      expect(test_class.storage_id_for_key("AluminumHead:123")).
        to eq("AluminumHead:123")
    end

    it "returns key with storage type at beginning" do
      expect(test_class.storage_id_for_key("123")).
        to eq("AluminumHead:123")
    end
  end

  describe ".many_to_one" do
    let(:association_class) { double }

    before(:each) do
      allow(subject).to receive(:spam_noodle_id).and_return("spam_noodle_id")
      allow(association_class).to receive(:fetch).
        with("spam_noodle_id", :hive => hive).and_return(:the_object)
    end

    it "adds helper method to retrieve association" do
      allow(Swarm::Support).to receive(:constantize).
        with("spam_noodle").and_return(association_class)
      test_class.many_to_one :spam_noodle
      expect(subject.spam_noodle).to eq(:the_object)
    end

    it "allows for override of class_name" do
      allow(Swarm::Support).to receive(:constantize).
        with("MyUnclesTruck").and_return(association_class)
      test_class.many_to_one :spam_noodle, :class_name => "MyUnclesTruck"
      expect(subject.spam_noodle).to eq(:the_object)
    end

    it "memoizes association" do
      allow(Swarm::Support).to receive(:constantize).
        with("spam_noodle").and_return(association_class)
      test_class.many_to_one :spam_noodle
      expect(subject.spam_noodle).to eq(:the_object)
      allow(subject).to receive(:spam_noodle_id).and_return("not_spam_noodle_id")
      expect(subject.spam_noodle).to eq(:the_object)
    end
  end

  describe ".storage_type" do
    it "returns demodularized class name" do
      expect(test_class.storage_type).to eq("AluminumHead")
    end
  end

  describe ".ids" do
    it "returns all ids for storage type" do
      allow(hive.storage).to receive(:ids_for_type).with("AluminumHead").
        and_return(:all_the_ids)
      expect(test_class.ids(:hive => hive)).to eq(:all_the_ids)
    end
  end

  describe ".all" do
    it "fetches an instance for every id returned by .ids, if is_a? class" do
      allow(test_class).to receive(:ids).with(:hive => hive).
        and_return(["123", "456", "789", "boo"])
      doubles = ["123", "456", "789"].map do |id|
        instance_double(test_class).tap { |double|
          allow(double).to receive(:is_a?).with(test_class).and_return(true)
          allow(test_class).to receive(:fetch).with(id, :hive => hive).and_return(double)
        }
      end
      allow(test_class).to receive(:fetch).with("boo", :hive => hive).and_return(double(:is_a? => false))
      expect(test_class.all(:hive => hive)).to eq(doubles)
    end

    it "restricts to instances of class specifically if subtypes false" do
      allow(test_class).to receive(:ids).with(:hive => hive).
        and_return(["123", "456", "789", "boo"])
      doubles = ["123", "456", "789"].map do |id|
        instance_double(test_class, :class => test_class).tap { |double|
          allow(test_class).to receive(:fetch).with(id, :hive => hive).and_return(double)
        }
      end
      sub_double = double(:class => "Nope", :is_a? => true)
      allow(test_class).to receive(:fetch).with("boo", :hive => hive).and_return(sub_double)
      expect(test_class.all(:hive => hive, :subtypes => false)).to eq(doubles)
    end
  end
end
