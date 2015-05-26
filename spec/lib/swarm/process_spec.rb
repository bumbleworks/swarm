describe Swarm::Process do
  let(:params) { { :hive => hive, :process_definition_id => '123', :workitem => "the workitem"} }
  subject { described_class.create(params) }

  describe "#process_definition" do
    it "returns process definition for this process" do
      allow(Swarm::ProcessDefinition).to receive(:fetch).
        with('123', :hive => hive).
        and_return(:the_definition)
      expect(subject.process_definition).to eq(:the_definition)
    end
  end

  describe "#launch" do
    it "queues a launch of this process in the hive" do
      expect(hive).to receive(:queue).with('launch', subject)
      subject.launch
    end
  end

  describe "#_launch" do
    let(:root_expression) { instance_double(Swarm::SequenceExpression, :id => '123') }
    before(:each) do
      allow(Swarm::SequenceExpression).to receive(:create).
        with({
          :hive => hive,
          :parent_id => subject.id,
          :position => 0,
          :workitem => "the workitem",
          :process_id => subject.id
        }).and_return(root_expression)
    end

    it "creates the root expression and applies it" do
      expect(root_expression).to receive(:apply)
      subject._launch
    end

    it "associates the root expression and saves" do
      allow(root_expression).to receive(:apply)
      subject._launch
      expect(subject.root_expression_id).to eq('123')
    end
  end

  describe "#node_at_position" do
    it "returns full tree from definition if position 0 requested" do
      allow(subject).to receive(:process_definition).
        and_return(double(:tree => :the_tree))
      expect(subject.node_at_position(0)).to eq(:the_tree)
    end

    it "raises ArgumentError if any position other than 0 requested" do
      expect {
        subject.node_at_position(1)
      }.to raise_error(ArgumentError)
    end
  end

  describe "#root_expression" do
    it "fetches launched root expression" do
      allow(Swarm::Expression).to receive(:fetch).
        with('456', :hive => hive).
        and_return(:the_expression)
      allow(subject).to receive(:root_expression_id).and_return('456')
      expect(subject.root_expression).to eq(:the_expression)
    end
  end

  describe "#move_on_from" do
    it "sets the workitem to the given child expression's workitem" do
      expect(subject.workitem).to eq("the workitem")
      expression = instance_double(Swarm::Expression, :workitem => :a_new_workitem)
      subject.move_on_from(expression)
      expect(subject.workitem).to eq(:a_new_workitem)
    end
  end
end