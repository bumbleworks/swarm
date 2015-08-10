RSpec.describe Swarm::StorageParticipant do
  let(:expression) {
    Swarm::ActivityExpression.new_from_storage({
      :hive => hive,
      :workitem => { :bubbles => :shiny },
      :process_id => "bonkers"
    })
  }
  subject {
    described_class.new({
      :hive => hive,
      :expression => expression
    })
  }

  before(:each) do
    allow(expression).to receive(:node).and_return(["badabingle", {"some words" => nil}, []])
  end

  describe "#work" do
    it "creates a StoredWorkitem for expression" do
      expect(Swarm::StoredWorkitem).to receive(:create).with({
        :hive => hive,
        :expression_id => expression.id,
        :process_id => "bonkers",
        :workitem => { :bubbles => :shiny }
      })
      subject.work
    end
  end
end