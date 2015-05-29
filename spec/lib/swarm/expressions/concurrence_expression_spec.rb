describe Swarm::ConcurrenceExpression do
  subject {
    described_class.new_from_storage({
      :hive => hive,
      :id => 'foo',
      :workitem => { 'foo' => 'bar' },
      :process_id => '123',
      :parent_id => '456'
    })
  }

  before(:each) do
    allow(subject).to receive(:node).and_return(["concurrence", {}, [:a, :b]])
  end

  describe "#_apply" do
    around(:each) do |example|
      Timecop.freeze do
        example.run
      end
    end

    it "sets applied_at milestone and kicks off all children" do
      expect(subject).to receive(:kick_off_children).with([0, 1])
      subject._apply
      expect(subject.milestones["applied_at"]).to eq(Time.now.to_i)
    end
  end

  describe "#all_children_replied?" do
    it "returns true if all children have replied" do
      allow(subject).to receive(:children).and_return([
        double(:replied_at => Time.now),
        double(:replied_at => Time.now)
      ])
      expect(subject.all_children_replied?).to eq(true)
    end

    it "returns false if some children have not replied" do
      allow(subject).to receive(:children).and_return([
        double(:replied_at => Time.now),
        double(:replied_at => nil)
      ])
      expect(subject.all_children_replied?).to eq(false)
    end

    it "returns false if num of replied children not equal to tree size" do
      allow(subject).to receive(:children).and_return([
        double(:replied_at => Time.now)
      ])
      expect(subject.all_children_replied?).to eq(false)
    end
  end

  describe "#move_on_from" do
    it "replies if all children have replied" do
      fake_child = double(:workitem => {})
      allow(subject).to receive(:all_children_replied?).and_return(true)
      expect(subject).to receive(:reply)
      subject.move_on_from(fake_child)
    end

    it "does not reply if still waiting for children" do
      fake_child = double(:workitem => {})
      allow(subject).to receive(:all_children_replied?).and_return(false)
      expect(subject).not_to receive(:reply)
      subject.move_on_from(fake_child)
    end

    it "merges child workitem into current workitem with deep merge and saves" do
      expect(subject).to receive(:merge_child_workitem).with(:fake_child).ordered
      expect(subject).to receive(:save).ordered
      subject.move_on_from(:fake_child)
    end
  end

  describe "#merge_child_workitem" do
    it "merges child workitem into current workitem with deep merge" do
      allow(subject).to receive(:array_combination_method).and_return("special")
      allow(Swarm::Support).to receive(:deep_merge).
        with(subject.workitem, :child_workitem, :combine_arrays => "special").
        and_return(:the_new_workitem)
      fake_child = double(:workitem => :child_workitem)
      subject.merge_child_workitem(fake_child)
      expect(subject.workitem).to eq(:the_new_workitem)
    end
  end

  describe "#array_combination_method" do
    it "returns uniq by default" do
      expect(subject.array_combination_method).to eq("uniq")
    end

    it "returns method from args" do
      allow(subject).to receive(:arguments).and_return({"combine_arrays" => "override"})
      expect(subject.array_combination_method).to eq("override")
      allow(subject).to receive(:arguments).and_return({"combine_arrays" => "concat"})
      expect(subject.array_combination_method).to eq("concat")
    end
  end
end