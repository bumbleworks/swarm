RSpec.describe Swarm::StorageParticipant do
  let(:expression) {
    Swarm::ActivityExpression.new_from_storage(
      workitem: { bubbles: :shiny },
      process_id: "bonkers",
      id: "crazy-id"
    )
  }
  subject {
    described_class.new(
      expression: expression
    )
  }

  before(:each) do
    allow(expression).to receive(:node).and_return(["badabingle", {"some words" => nil}, []])
  end

  describe "#work" do
    it "creates a StoredWorkitem for expression" do
      expect(Swarm::StoredWorkitem).to receive(:create).with({
        hive: hive,
        expression_id: "crazy-id"
      })
      subject.work
    end
  end
end
