RSpec.describe Swarm::ProcessDefinition do
  let(:json) { File.read(fixtures_path.join('concurrence_process.json')) }
  let(:parsed_json) { JSON.parse(json) }
  subject { described_class.create_from_json(json) }

  describe ".create_from_pollen" do
    it "transforms pollen to JSON and then delegates to .create_from_json" do
      allow(Swarm::Pollen::Reader).to receive(:new).
        with(:some_pollen).
        and_return(double(:to_json => :a_json_version))
      allow(described_class).to receive(:create_from_json).
        with(:a_json_version, hive: "amazing hive").
        and_return(:the_result)
      expect(described_class.create_from_pollen(:some_pollen, hive: "amazing hive")).
        to eq(:the_result)
    end
  end

  describe ".create_from_json" do
    context "when json only contains tree" do
      let(:json) { File.read(fixtures_path.join('no_metadata_process.json')) }

      it "sets tree to parsed tree from JSON" do
        expect(subject.tree).to eq(parsed_json)
      end

      it "persists new definition in storage" do
        retrieved_subject = described_class.fetch(subject.id, :hive => hive)
        expect(retrieved_subject.tree).to eq(parsed_json)
      end
    end

    context "when json also contains metadata" do
      let(:json) { File.read(fixtures_path.join('conditional_process.json')) }

      it "sets name, version, and tree from JSON" do
        expect(subject.tree).to eq(parsed_json["definition"])
        expect(subject.name).to eq(parsed_json["name"])
        expect(subject.version).to eq(parsed_json["version"])
      end

      it "persists new definition in storage" do
        retrieved_subject = described_class.fetch(subject.id, :hive => hive)
        expect(retrieved_subject.tree).to eq(parsed_json["definition"])
      end
    end
  end

  describe ".find_by_name" do
    it "returns the saved process definition with the given name" do
      one = described_class.create(:name => "one")
      two = described_class.create(:name => "two")
      expect(described_class.find_by_name("one")).to eq(one)
      expect(described_class.find_by_name("two")).to eq(two)
    end

    it "returns nil if no definition found with given name" do
      expect(described_class.find_by_name("three")).to be_nil
    end
  end

  describe "#launch_process" do
    it "creates and launches process from this definition" do
      process = instance_double(Swarm::Process)
      expect(subject).to receive(:create_process).
        with(workitem: "the workitem", arg2: "arg2").
        and_return(process)
      expect(process).to receive(:launch)
      subject.launch_process(workitem: "the workitem", arg2: "arg2")
    end
  end

  describe "#create_process" do
    it "creates a new process from this definition" do
      allow(Swarm::Process).to receive(:create).with({
        :process_definition_id => subject.id,
        :workitem => "the workitem",
        :arg2 => "arg2"
      }).and_return(:the_process)

      expect(subject.create_process(workitem: "the workitem", arg2: "arg2")).to eq(:the_process)
    end

    it "raises error if definition has not been saved" do
      allow(subject).to receive(:id).and_return(nil)
      expect {
        subject.create_process(workitem: "the workitem")
      }.to raise_error(described_class::NotYetPersistedError)
    end
  end
end