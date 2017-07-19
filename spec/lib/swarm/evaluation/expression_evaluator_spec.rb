RSpec.describe Swarm::ExpressionEvaluator do
  let(:expression) { double(:workitem => { "foo" => 1, "bar" => 2 }) }
  subject { described_class.new(expression) }

  describe "#eval" do
    it "evaluates string in context of workitem" do
      context = double(Swarm::WorkitemContext)
      allow(Swarm::WorkitemContext).to receive(:new).
        with(subject.workitem).
        and_return(context)
      allow(context).to receive(:instance_eval).
        with("a string").
        and_return("an evaluated string")
      expect(subject.eval("a string")).to eq("an evaluated string")
    end
  end

  describe "#check_condition" do
    before(:each) do
      allow(subject).to receive(:eval).with("it is true").and_return(true)
      allow(subject).to receive(:eval).with("it is false").and_return(false)
    end

    it "returns true if 'if' expression evaluates to true" do
      expect(subject.check_condition("if", "it is true")).to eq(true)
    end

    it "returns false if 'if' expression evaluates to false" do
      expect(subject.check_condition("if", "it is false")).to eq(false)
    end

    it "returns true if 'unless' expression evaluates to false" do
      expect(subject.check_condition("unless", "it is false")).to eq(true)
    end

    it "returns false if 'unless' expression evaluates to true" do
      expect(subject.check_condition("unless", "it is true")).to eq(false)
    end

    it "raises ArgumentError if given a non-conditional type" do
      expect {
        subject.check_condition("ploomits", "it is true")
      }.to raise_error(ArgumentError)
    end
  end

  describe "#all_conditions_met?" do
    before(:each) do
      allow(subject).to receive(:conditions).
        and_return({ "if" => "yay == 1", "unless" => "boo == 2" })
    end

    it "returns true if all conditional arguments meet expectations" do
      allow(subject).to receive(:eval).with("yay == 1").and_return(true)
      allow(subject).to receive(:eval).with("boo == 2").and_return(false)
      expect(subject.all_conditions_met?).to eq(true)
    end

    it "returns false if any conditional arguments don't meet expectations" do
      allow(subject).to receive(:eval).with("yay == 1").and_return(true)
      allow(subject).to receive(:eval).with("boo == 2").and_return(true)
      expect(subject.all_conditions_met?).to eq(false)
    end
  end

  describe "#conditions" do
    it "returns conditional arguments" do
      allow(subject).to receive(:arguments).
        and_return({ "if" => "yay", "unless" => "boo", "gnu" => "spork" })
      expect(subject.conditions).to eq({ "if" => "yay", "unless" => "boo" })
    end

    it "returns empty array if no conditional arguments" do
      allow(subject).to receive(:arguments).
        and_return({ "gnu" => "spork" })
      expect(subject.conditions).to eq({})
    end
  end
end
