RSpec.describe Swarm::Expression do
  subject {
    described_class.new(
      hive: hive,
      process_id: '123',
      parent_id: '456'
    )
  }

  describe "#process" do
    it "returns process for this expression" do
      allow(Swarm::Process).to receive(:fetch).
        with('123', hive: hive).
        and_return(:the_process)
      expect(subject.process).to eq(:the_process)
    end
  end

  describe "#branch_position" do
    it "returns last element in position" do
      subject.position = [0, 1, 3]
      expect(subject.branch_position).to eq(3)
    end
  end

  describe "#evaluator" do
    it "returns an ExpressionEvaluator for the expression" do
      evaluator = double(Swarm::ExpressionEvaluator)
      allow(Swarm::ExpressionEvaluator).to receive(:new).
        with(subject).
        and_return(evaluator)
      expect(subject.evaluator).to eq(evaluator)
    end
  end

  describe "#meets_conditions?" do
    it "asks evaluator if all_conditions_met?" do
      allow(subject.evaluator).to receive(:all_conditions_met?).and_return(:answer)
      expect(subject.meets_conditions?).to eq(:answer)
    end
  end

  describe "#root?" do
    it "returns true if parent is same as process" do
      subject.parent_id = '123'
      expect(subject.root?).to eq(true)
    end

    it "returns false if parent is not same as process" do
      expect(subject.root?).to eq(false)
    end
  end

  describe "#parent" do
    it "returns process if root expression" do
      subject.parent_id = '123'
      allow(subject).to receive(:process).and_return(:the_process)
      expect(subject.parent).to eq(:the_process)
    end

    it "returns parent expression if not root" do
      allow(Swarm::Expression).to receive(:fetch).
        with('456', hive: hive).
        and_return(:the_parent_expression)
      expect(subject.parent).to eq(:the_parent_expression)
    end
  end

  describe "#apply" do
    it "queues an apply of this expression in the hive" do
      expect(hive).to receive(:queue).with('apply', subject)
      subject.apply
    end
  end

  describe "#_apply" do
    around(:each) do |example|
      Timecop.freeze do
        example.run
      end
    end

    it "sets applied_at milestone, calls #work, and saves" do
      allow(subject).to receive(:meets_conditions?).and_return(true)
      expect(subject).to receive(:work).ordered
      expect(subject).to receive(:reply).never
      expect(subject).to receive(:save).ordered
      subject._apply
      expect(subject.milestones["applied_at"]).to eq(Time.now.to_i)
    end

    it "calls #reply instead of #work if conditions not met" do
      allow(subject).to receive(:meets_conditions?).and_return(false)
      expect(subject).to receive(:work).never
      expect(subject).to receive(:reply).ordered
      expect(subject).to receive(:save).ordered
      subject._apply
      expect(subject.milestones["applied_at"]).to eq(Time.now.to_i)
    end
  end

  describe "#reply" do
    it "saves and queues a reply of this expression in the hive" do
      expect(subject).to receive(:save).ordered
      expect(hive).to receive(:queue).with('reply', subject).ordered
      subject.reply
    end
  end

  describe "#_reply" do
    around(:each) do |example|
      Timecop.freeze do
        example.run
      end
    end

    it "sets replied_at milestone and replies to parent" do
      expect(subject).to receive(:reply_to_parent)
      subject._reply
      expect(subject.milestones["replied_at"]).to eq(Time.now.to_i)
    end
  end

  describe "#reply_to_parent" do
    it "tells parent to move on" do
      parent_expression = instance_double(Swarm::SequenceExpression)
      allow(subject).to receive(:parent).
        and_return(parent_expression)
      expect(parent_expression).to receive(:move_on_from).with(subject).ordered
      subject._reply
    end
  end

  describe "#replied_at" do
    it "returns time from replied_at milestone" do
      subject.milestones = { "replied_at" => 123456789 }
      expect(subject.replied_at).to eq(123456789)
    end
  end

  describe "#replied?" do
    before(:each) do
      allow(subject).to receive(:reload!)
    end

    it "calls reload! before checking replied_at" do
      expect(subject).to receive(:reload!).ordered
      expect(subject).to receive(:replied_at).ordered
      subject.replied?
    end

    it "returns true if replied_at not nil" do
      subject.milestones = { "replied_at" => 123456789 }
      expect(subject.replied?).to eq(true)
    end

    it "returns false if replied_at nil" do
      subject.milestones = { "replied_at" => nil}
      expect(subject.replied?).to eq(false)
    end

    it "returns false if replied_at missing" do
      subject.milestones = {}
      expect(subject.replied?).to eq(false)
    end
  end

  describe "#node" do
    it "returns node at expression's position from parent's tree" do
      subject.position = [1, 2, 8]
      parent_expression = instance_double(Swarm::SequenceExpression)
      allow(subject).to receive(:parent).
        and_return(parent_expression)
      allow(parent_expression).to receive(:node_at_position).
        with(8).and_return(:a_node)
      expect(subject.node).to eq(:a_node)
    end
  end

  context "node part accessors" do
    let(:node) { ["a_command", { args: :foo }, [:fake, :tree]] }
    before(:each) do
      allow(subject).to receive(:node).and_return(node)
    end

    describe "#command" do
      it "returns first element from node" do
        expect(subject.command).to eq("a_command")
      end
    end

    describe "#arguments" do
      it "returns second element from node" do
        expect(subject.arguments).to eq({ args: :foo })
      end
    end

    describe "#tree" do
      it "returns third element from node" do
        expect(subject.tree).to eq([:fake, :tree])
      end
    end

    describe "#node_at_position" do
      it "returns element from tree at given position" do
        expect(subject.node_at_position(0)).to eq(:fake)
        expect(subject.node_at_position(1)).to eq(:tree)
        expect(subject.node_at_position(2)).to be_nil
      end
    end
  end
end
