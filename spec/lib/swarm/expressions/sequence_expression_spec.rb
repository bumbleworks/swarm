describe Swarm::SequenceExpression do
  subject {
    described_class.new({
      :hive => hive,
      :id => 'foo',
      :workitem => { 'foo' => 'bar' },
      :process_id => '123',
      :parent_id => '456'
    })
  }

  before(:each) do
    allow(subject).to receive(:node).and_return(["sequence", {}, [:a, :b]])
  end

  describe "#_apply" do
    around(:each) do |example|
      Timecop.freeze do
        example.run
      end
    end

    it "sets applied_at milestone and kicks off first child" do
      expect(subject).to receive(:kick_off_children).with([0])
      subject._apply
      expect(subject.milestones["applied_at"]).to eq(Time.now.to_i)
    end
  end

  describe "#move_on_from" do
    it "sets workitem to child's workitem and kicks off next child" do
      expect(subject).to receive(:kick_off_children).with([84])
      expect(subject).not_to receive(:reply)
      subject.move_on_from(double(:workitem => :a_workitem, :position => 83))
      expect(subject.workitem).to eq(:a_workitem)
    end

    it "replies if next child doesn't exist" do
      allow(subject).to receive(:kick_off_children).with([84]).
        and_raise(described_class::InvalidPositionError)
      expect(subject).to receive(:reply)
      subject.move_on_from(double(:workitem => :a_workitem, :position => 83))
    end
  end
end