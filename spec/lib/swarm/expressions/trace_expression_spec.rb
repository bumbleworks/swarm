RSpec.describe Swarm::TraceExpression do
  subject {
    described_class.new_from_storage({
      :hive => hive,
      :workitem => {}
    })
  }

  before(:each) do
    allow(subject).to receive(:node).and_return(["trace", {"some words" => nil}, []])
  end

  describe "#work" do
    it "adds argument to workitem and hive trace and replies" do
      subject.workitem = { "traced" => ["first words"] }
      hive.trace("first words")
      expect(subject).to receive(:reply)
      subject.work
      expect(subject.reload!.workitem).to eq({ "traced" => ["first words", "some words"] })
      expect(hive.traced).to eq(["first words", "some words"])
    end

    it "initializes traces if nonexistent" do
      subject.work
      expect(subject.reload!.workitem).to eq({ "traced" => ["some words"] })
      expect(hive.traced).to eq(["some words"])
    end
  end
end