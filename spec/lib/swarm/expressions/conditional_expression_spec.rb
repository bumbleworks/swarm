RSpec.describe Swarm::ConditionalExpression do
  let(:branches) { { "true" => [:a], "false" => [:b] } }

  subject {
    described_class.new_from_storage({
      :id => 'foo',
      :workitem => { 'foo' => 'bar' },
      :process_id => '123',
      :parent_id => '456'
    })
  }

  before(:each) do
    allow(subject).to receive(:node).and_return(
      ["if", { "condition" => "horse > pony" }, branches]
    )
  end

  describe "#work" do
    it "kicks off first child if tree is not empty" do
      allow(subject).to receive(:tree).and_return(["a branch"])
      expect(subject).to receive(:kick_off_children).with([0])
      expect(subject).to receive(:reply).never
      subject.work
    end

    it "replies if tree is empty" do
      allow(subject).to receive(:tree).and_return([])
      expect(subject).to receive(:kick_off_children).never
      expect(subject).to receive(:reply)
      subject.work
    end
  end

  describe "#move_on_from" do
    it "sets workitem to child's workitem and replies" do
      expect(subject).to receive(:reply)
      subject.move_on_from(double(:workitem => :a_workitem))
      expect(subject.workitem).to eq(:a_workitem)
    end
  end

  describe "#tree" do
    it "returns 'true' branch if condition is met" do
      allow(subject).to receive(:branch_condition_met?).
        and_return(true)
      expect(subject.tree).to eq([:a])
    end

    it "returns 'false' branch if condition is not met" do
      allow(subject).to receive(:branch_condition_met?).
        and_return(false)
      expect(subject.tree).to eq([:b])
    end

    context "resolved branch does not exist" do
      let(:branches) { { "true" => [:a] } }

      it "returns empty tree" do
        allow(subject).to receive(:branch_condition_met?).
          and_return(false)
        expect(subject.tree).to eq([])
      end
    end
  end

  describe "#branch_condition_met?" do
    it "asks evaluator if given condition matches given command" do
      allow(subject).to receive(:command).and_return(:a_command)
      allow(subject.evaluator).to receive(:check_condition).
        with(:a_command, "horse > pony").
        and_return(:answer)
      expect(subject.branch_condition_met?).to eq(:answer)
    end
  end
end