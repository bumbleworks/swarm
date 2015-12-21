RSpec.describe Swarm::Router do
  describe ".expression_class_for_node" do
    it "returns SequenceExpression when command is sequence" do
      node = ["sequence", {}, []]
      expect(described_class.expression_class_for_node(node)).to eq(Swarm::SequenceExpression)
    end

    it "returns ConcurrenceExpression when command is concurrence" do
      node = ["concurrence", {}, []]
      expect(described_class.expression_class_for_node(node)).to eq(Swarm::ConcurrenceExpression)
    end

    it "returns SubprocessExpression when command is subprocess" do
      node = ["subprocess", {}, []]
      expect(described_class.expression_class_for_node(node)).to eq(Swarm::SubprocessExpression)
    end

    it "returns ActivityExpression when command is not branch" do
      node = ["badabingle", {}, []]
      expect(described_class.expression_class_for_node(node)).to eq(Swarm::ActivityExpression)
    end
  end
end
