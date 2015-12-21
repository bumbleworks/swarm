RSpec.describe Swarm::Pollen::Reader do
  let(:pollen) { File.read(fixture_path("#{process_type}.pollen")) }
  let(:json) { File.read(fixture_path("#{process_type}.json")) }
  subject { described_class.new(pollen) }

  describe "#to_hash" do
    context "with metadata-decorated process" do
      let(:process_type) { "conditional_process" }
      it "should return hash of transformed pollen" do
        expect(subject.to_hash).to eq(JSON.parse(json))
      end
    end

    context "with process containing argument-less commands" do
      let(:process_type) { "concurrence_process" }
      it "should return hash of transformed pollen" do
        expect(subject.to_hash).to eq(JSON.parse(json))
      end
    end
  end

  describe "#to_json" do
    let(:process_type) { "conditional_process" }
    it "returns JSON version of #to_hash" do
      expect(subject).to receive(:to_hash).
        and_return(double(:to_json => :a_json_version))
      expect(subject.to_json).to eq(:a_json_version)
    end
  end
end
