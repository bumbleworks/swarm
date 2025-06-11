# frozen_string_literal: true

RSpec.describe Swarm::ConcurrenceExpression do
  let(:node) { ["concurrence", {}, [:a, :b]] }
  subject {
    described_class.new_from_storage(
      id: 'foo',
      workitem: { 'foo' => 'bar' },
      process_id: '123',
      parent_id: '456'
    )
  }

  before(:each) do
    allow(subject).to receive(:node).and_return(node)
  end

  describe "#work" do
    it "kicks off all children" do
      expect(subject).to receive(:kick_off_children).with([0, 1])
      subject.work
    end
  end

  describe "#ready_to_proceed?" do
    context "with default concurrence" do
      it "defers to #all_children_replied?" do
        allow(subject).to receive(:all_children_replied?).
          and_return(:true_or_false)
        expect(subject.ready_to_proceed?).to eq(:true_or_false)
      end
    end

    context "with required_replies argument" do
      let(:node) { ["concurrence", { "required_replies" => 3 }, [:a, :b, :c, :d]] }

      it "returns true when replied children count is equal to required replies" do
        allow(subject).to receive(:replied_children).
          and_return(Array.new(3, :foo))
        expect(subject.ready_to_proceed?).to eq(true)
      end

      it "returns true when replied children count is greater than required replies" do
        allow(subject).to receive(:replied_children).
          and_return(Array.new(4, :foo))
        expect(subject.ready_to_proceed?).to eq(true)
      end

      it "returns false when replied children count is less than required replies" do
        allow(subject).to receive(:replied_children).
          and_return(Array.new(2, :foo))
        expect(subject.ready_to_proceed?).to eq(false)
      end
    end
  end

  describe "#replied_children" do
    it "returns children who have replied" do
      allow(subject).to receive(:children).and_return([
        child1 = double(replied_at: Time.now),
        child2 = double(replied_at: Time.now),
        double(replied_at: nil)
      ])
      expect(subject.replied_children).to match_array([child1, child2])
    end
  end

  describe "#all_children_replied?" do
    it "returns true if #replied_children equals tree size" do
      allow(subject).to receive(:replied_children).and_return(Array.new(2, :foo))
      expect(subject.all_children_replied?).to eq(true)
    end

    it "returns false if #replied_children does not equal tree size" do
      allow(subject).to receive(:replied_children).and_return(Array.new(1, :foo))
      expect(subject.all_children_replied?).to eq(false)
    end
  end

  describe "#move_on_from" do
    it "replies if all children have replied" do
      fake_child = double(workitem: {})
      allow(subject).to receive(:all_children_replied?).and_return(true)
      expect(subject).to receive(:reply)
      subject.move_on_from(fake_child)
    end

    it "does not reply if still waiting for children" do
      fake_child = double(workitem: {})
      allow(subject).to receive(:all_children_replied?).and_return(false)
      expect(subject).not_to receive(:reply)
      subject.move_on_from(fake_child)
    end

    it "merges child workitem into current workitem with deep merge and saves" do
      expect(subject).to receive(:merge_child_workitem).with(:fake_child).ordered
      expect(subject).to receive(:save).ordered
      allow(subject).to receive(:all_children_replied?).and_return(false)
      subject.move_on_from(:fake_child)
    end
  end

  describe "#merge_child_workitem" do
    it "merges child workitem into current workitem with deep merge" do
      allow(subject).to receive(:array_combination_method).and_return("special")
      allow(Swarm::Support).to receive(:deep_merge).
        with(subject.workitem, :child_workitem, combine_arrays: "special").
        and_return(:the_new_workitem)
      fake_child = double(workitem: :child_workitem)
      subject.merge_child_workitem(fake_child)
      expect(subject.workitem).to eq(:the_new_workitem)
    end
  end

  describe "#array_combination_method" do
    it "returns uniq by default" do
      expect(subject.array_combination_method).to eq("uniq")
    end

    it "returns method from args" do
      allow(subject).to receive(:arguments).and_return({ "combine_arrays" => "override" })
      expect(subject.array_combination_method).to eq("override")
      allow(subject).to receive(:arguments).and_return({ "combine_arrays" => "concat" })
      expect(subject.array_combination_method).to eq("concat")
    end
  end
end
