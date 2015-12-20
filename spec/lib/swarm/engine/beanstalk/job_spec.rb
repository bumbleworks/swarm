RSpec.describe Swarm::Engine::Beanstalk::Job do
  let(:job) { instance_double(Beaneater::Job) }
  subject { described_class.new(job) }

  describe "#to_h" do
    it "returns JSON parsed body with symbolized keys" do
      allow(subject).to receive(:body).
        and_return({ "foo" => "bar" }.to_json)
      expect(subject.to_h).to eq(foo: "bar")
    end
  end

  describe ".new" do
    it "returns a simple delegator for given object" do
      expect(subject).to be_a(SimpleDelegator)
      expect(subject.send(:__getobj__)).to eq(job)
    end
  end
end