# frozen_string_literal: true

RSpec.describe Swarm::StoredWorkitem do
  let(:expression) {
    Swarm::ActivityExpression.create(
      workitem: { "bubbles" => "shiny" },
      process_id: "bonkers"
    )
  }
  subject {
    described_class.create(
      expression_id: expression.id
    )
  }

  before(:each) do
    allow(expression).to receive(:node).and_return(["badabingle", { "some words" => nil }, []])
  end

  describe "#workitem" do
    it "delegates to expression" do
      expect(subject.workitem).to eq({ "bubbles" => "shiny" })
    end
  end

  describe "#proceed" do
    it "replies to parent and deletes self" do
      expect(subject).to receive(:delete).ordered
      expect(subject.expression).to receive(:reply).ordered
      subject.proceed
    end
  end
end
