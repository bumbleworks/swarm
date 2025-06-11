# frozen_string_literal: true

RSpec.describe Swarm::ActivityExpression do
  subject {
    described_class.new_from_storage(
      id: 'foo',
      workitem: { 'foo' => 'bar' },
      process_id: '123',
      parent_id: '456'
    )
  }

  let(:participant) { double("participant") }

  context "with trace node" do
    before(:each) do
      allow(subject).to receive(:node).and_return(["trace", { "some words" => nil }, []])
    end

    describe "#work" do
      it "instantiates trace participant and calls work" do
        expect(participant).to receive(:work)
        allow(Swarm::TraceParticipant).to receive(:new).
          with(hive: hive, expression: subject).
          and_return(participant)
        subject.work
      end
    end
  end

  context "with unrecognized node" do
    before(:each) do
      allow(subject).to receive(:node).and_return(["badabingle", {}, []])
    end

    describe "#work" do
      it "instantiates storage participant and calls work" do
        expect(participant).to receive(:work)
        allow(Swarm::StorageParticipant).to receive(:new).
          with(hive: hive, expression: subject).
          and_return(participant)
        subject.work
      end
    end
  end
end
