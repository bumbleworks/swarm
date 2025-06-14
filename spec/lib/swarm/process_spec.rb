# frozen_string_literal: true

RSpec.describe Swarm::Process do
  let(:params) { { process_definition_id: '123', workitem: "the workitem" } }
  subject { described_class.create(**params) }

  describe "#wait_until_finished" do
    it "waits until finished" do
      allow(subject).to receive(:finished?).and_return(false, true)
      subject.wait_until_finished
    end

    it "times out if not finished in time" do
      allow(subject).to receive(:finished?).and_return(false)
      expect {
        subject.wait_until_finished(timeout: 0.05)
      }.to raise_error(Timeout::Error)
    end
  end

  describe "#process_definition" do
    it "returns process definition for this process" do
      allow(Swarm::ProcessDefinition).to receive(:fetch).
        with('123', hive: hive).
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
    let(:root_expression) { instance_double(Swarm::SequenceExpression, id: '123') }
    before(:each) do
      allow(Swarm::SequenceExpression).to receive(:create).
        with(
          hive: hive,
          parent_id: subject.id,
          position: [0],
          workitem: "the workitem",
          process_id: subject.id
        ).and_return(root_expression)
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
        and_return(double(tree: :the_tree))
      expect(subject.node_at_position(0)).to eq(:the_tree)
    end

    it "raises ArgumentError if any position other than 0 requested" do
      expect {
        subject.node_at_position(1)
      }.to raise_error(ArgumentError)
    end
  end

  describe "#finished?" do
    let(:root_expression) { Swarm::Expression.create }
    it "reloads and returns true if root expression is replied" do
      allow(root_expression).to receive(:replied?).and_return(true)
      expect(subject).to receive(:reload!).ordered
      allow(subject).to receive(:root_expression).
        and_return(root_expression).ordered
      expect(subject).to be_finished
    end

    it "returns false if root expression is not replied" do
      allow(root_expression).to receive(:replied?).and_return(false)
      allow(subject).to receive(:root_expression).
        and_return(root_expression)
      expect(subject).not_to be_finished
    end

    it "returns false if no root_expression" do
      allow(subject).to receive(:root_expression).
        and_return(nil)
      expect(subject).not_to be_finished
    end
  end

  describe "#parent_expression" do
    before(:each) do
      allow(Swarm::Expression).to receive(:fetch).
        with('789', hive: hive).
        and_return(:the_expression)
    end

    it "fetches parent expression from launch" do
      allow(subject).to receive(:parent_expression_id).and_return('789')
      expect(subject.parent_expression).to eq(:the_expression)
    end

    it "returns nil if no parent_expression_id" do
      allow(subject).to receive(:parent_expression_id).and_return(nil)
      expect(subject.parent_expression).to be_nil
    end
  end

  describe "#root_expression" do
    before(:each) do
      allow(Swarm::Expression).to receive(:fetch).
        with('456', hive: hive).
        and_return(:the_expression)
    end

    it "fetches launched root expression" do
      allow(subject).to receive(:root_expression_id).and_return('456')
      expect(subject.root_expression).to eq(:the_expression)
    end

    it "returns nil if no root_expression_id" do
      allow(subject).to receive(:root_expression_id).and_return(nil)
      expect(subject.root_expression).to be_nil
    end

    it "does not cache if not found" do
      allow(subject).to receive(:root_expression_id).and_return(nil, '456')
      expect(subject.root_expression).to be_nil
      expect(subject.root_expression).to eq(:the_expression)
    end
  end

  describe "#move_on_from" do
    it "sets the workitem to the given child expression's workitem and saves" do
      expression = instance_double(Swarm::Expression, workitem: "a_new_workitem")
      subject.move_on_from(expression)
      expect(subject.reload!.workitem).to eq("a_new_workitem")
    end

    it "tells parent to move on if parent exists" do
      parent_expression = double(Swarm::Expression)
      allow(subject).to receive(:parent_expression).and_return(parent_expression)
      expect(parent_expression).to receive(:move_on_from).with(subject)
      subject.move_on_from(double(Swarm::Expression, workitem: "a_new_workitem"))
    end
  end

  describe "#process_definition_name" do
    it "delegates to process_definition #name" do
      allow(subject).to receive(:process_definition).
        and_return(double(name: "A special process"))
      expect(subject.process_definition_name).to eq("A special process")
    end
  end
end
