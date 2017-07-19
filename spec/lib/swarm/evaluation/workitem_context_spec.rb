RSpec.describe Swarm::WorkitemContext do
  subject { described_class.new({ "foo" => "bar", :baz => "luhrmann"}) }

  describe "#method_missing" do
    it "returns value from workitem if method matches key" do
      expect(subject.foo).to eq("bar")
      expect(subject.baz).to eq("luhrmann")
    end

    it "raises NoMethodError if method does not match key in workitem" do
      expect {
        subject.smooters
      }.to raise_error(NoMethodError)
    end
  end
end
