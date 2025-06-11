# frozen_string_literal: true

RSpec.describe Swarm::ExpressionEvaluator do
  let(:expression) { double(workitem: { "foo" => 1, "bar" => 2 }) }
  subject { described_class.new(expression) }

  describe "#evaluate_condition" do
    it "evaluates string in context of workitem" do
      expect(subject.evaluate_condition("(1 + foo) * bar")).to eq(4)
    end

    it "raises exception if evaluation fails" do
      expect {
        subject.evaluate_condition("1 + baz")
      }.to raise_error(described_class::UndefinedExpressionVariableError)
    end

    it "raises exception if expression is not a string" do
      expect {
        subject.evaluate_condition("4 *")
      }.to raise_error(described_class::InvalidExpressionError)
    end
  end

  describe "#check_condition" do
    before(:each) do
      allow(subject).to receive(:evaluate_condition).
        with("it is true").
        and_return(true)
      allow(subject).to receive(:evaluate_condition).
        with("it is false").
        and_return(false)
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
      allow(subject).to receive(:evaluate_condition).with("yay == 1").and_return(true)
      allow(subject).to receive(:evaluate_condition).with("boo == 2").and_return(false)
      expect(subject.all_conditions_met?).to eq(true)
    end

    it "returns false if any conditional arguments don't meet expectations" do
      allow(subject).to receive(:evaluate_condition).with("yay == 1").and_return(true)
      allow(subject).to receive(:evaluate_condition).with("boo == 2").and_return(true)
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
