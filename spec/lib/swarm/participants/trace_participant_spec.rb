RSpec.describe Swarm::TraceParticipant do
  let(:expression) {
    Swarm::ActivityExpression.new_from_storage({
      :hive => hive,
      :workitem => {},
    })
  }
  subject {
    described_class.new({
      :hive => hive,
      :expression => expression
    })
  }

  before(:each) do
    allow(expression).to receive(:node).and_return(["trace", {"some words" => nil}, []])
  end

  describe "#work" do
    it "adds argument to expression's workitem and hive trace and replies" do
      expression.workitem = { "traced" => ["first words"] }
      hive.trace("first words")
      expect(expression).to receive(:reply).and_call_original
      subject.work
      expect(expression.reload!.workitem).to eq({ "traced" => ["first words", "some words"] })
      expect(hive.traced).to eq(["first words", "some words"])
    end

    it "initializes traces if nonexistent" do
      subject.work
      expect(expression.reload!.workitem).to eq({ "traced" => ["some words"] })
      expect(hive.traced).to eq(["some words"])
    end
  end
end