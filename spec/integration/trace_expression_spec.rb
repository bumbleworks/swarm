RSpec.describe Swarm::Process, :type => :process do
  let(:json) { File.read(fixture_path) }
  let(:definition) { Swarm::ProcessDefinition.create_from_json(json) }
  subject { definition.launch_process({}) }

  context "with trace expressions" do
    let(:fixture_path) { fixtures_path.join('trace_process.json') }

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