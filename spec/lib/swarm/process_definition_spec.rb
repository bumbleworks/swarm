describe Swarm::ProcessDefinition do
  let(:json) { File.read(fixtures_path.join('process_definition.json')) }
  subject { described_class.create_from_json(json, :hive => @hive) }

  describe ".create_from_json" do
    it "sets tree to parsed tree from JSON" do
      expect(subject.tree).to eq(JSON.parse(json))
    end

    it "persists new definition in storage" do
      retrieved_subject = described_class.fetch(subject.id, :hive => @hive)
      expect(retrieved_subject.tree).to eq(JSON.parse(json))
    end
  end

  describe "#launch_process" do
    it "creates and launches process from this definition" do
      process = instance_double(Swarm::Process)
      expect(subject).to receive(:create_process).
        with("the workitem").
        and_return(process)
      expect(process).to receive(:launch)
      subject.launch_process("the workitem")
    end
  end

  describe "#create_process" do
    it "creates a new process from this definition" do
      allow(Swarm::Process).to receive(:create).with({
        :hive => @hive,
        :process_definition_id => subject.id,
        :workitem => "the workitem"
      }).and_return(:the_process)

      expect(subject.create_process("the workitem")).to eq(:the_process)
    end

    it "raises error if definition has not been saved" do
      allow(subject).to receive(:id).and_return(nil)
      expect {
        subject.create_process("the workitem")
      }.to raise_error(described_class::NotYetPersistedError)
    end
  end
end