RSpec.describe Swarm::Process, :process => true do
  let(:pollen) { File.read(fixtures_path.join('trace_process.pollen')) }
  let(:definition) { Swarm::ProcessDefinition.create_from_pollen(pollen) }
  subject { definition.launch_process(:workitem => {}) }

  context "with trace expressions" do
    it "runs and collects traces from expressions" do
      subject.wait_until_finished
      expect(hive.traced).to eq([
        "first string",
        "second string",
        "third string",
        "fourth string",
        "final string"
      ])
    end
  end
end
