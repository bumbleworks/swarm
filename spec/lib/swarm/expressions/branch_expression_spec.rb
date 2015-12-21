RSpec.describe Swarm::BranchExpression do
  subject {
    described_class.new_from_storage({
      :id => 'foo',
      :workitem => { 'foo' => 'bar' },
      :process_id => '123',
      :parent_id => '456',
      :position => [3]
    })
  }

  describe "#children" do
    it "returns an empty array if no children" do
      expect(subject.children).to be_empty
    end

    it "returns array of expressions for each child_id" do
      expressions = 3.times.collect { |id|
        Swarm::Expression.create(:hive => hive)
      }
      extra = Swarm::Expression.create(:hive => hive)
      subject.child_ids = expressions.map(&:id)
      expect(subject.children).to match_array(expressions)
    end
  end

  describe "#kick_off_children" do
    it "adds new children at given positions and applies them" do
      expect(subject).to receive(:add_and_apply_child).with(:first)
      expect(subject).to receive(:add_and_apply_child).with(:second)
      subject.kick_off_children([:first, :second])
    end
  end

  describe "#add_and_apply_child" do
    it "adds child at given position and applies it" do
      fake_expression = double
      expect(subject).to receive(:add_child).with(:the_position).
        and_return(fake_expression)
      expect(fake_expression).to receive(:apply)
      subject.add_and_apply_child(:the_position)
    end
  end

  describe "create_child_expression" do
    it "creates new child expression from given node at given position" do
      allow(Swarm::Router).to receive(:expression_class_for_node).
        with(:a_node).
        and_return(Swarm::ActivityExpression)
      allow(Swarm::ActivityExpression).to receive(:create).with({
        :hive => hive,
        :parent_id => "foo",
        :position => [3, 7],
        :workitem => { "foo" => "bar" },
        :process_id => "123"
      }).and_return(:the_expression)
      expect(subject.create_child_expression(:node => :a_node, :at_position => 7)).
        to eq(:the_expression)
    end
  end

  describe "add_child" do
    before(:each) do
      allow(subject).to receive(:tree).and_return([
        ["whatever", {}, []],
        ["another_one", {}, []]
      ])
    end

    it "creates new expression with given command and adds it to child_ids" do
      subject.child_ids = ["876"]
      fake_expression = double(:id => "987")
      allow(subject).to receive(:create_child_expression).
        with(:node => ["whatever", {}, []], :at_position => 0).
        and_return(fake_expression)
      subject.add_child(0)
      expect(subject.child_ids).to eq(["876", "987"])
    end

    it "raises exception if position doesn't exist in tree" do
      expect {
        subject.add_child(2)
      }.to raise_error(described_class::InvalidPositionError)
    end
  end
end