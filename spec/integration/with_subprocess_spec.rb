RSpec.describe Swarm::Process, :process => true do
  let(:pollen) { File.read(fixtures_path.join('with_subprocess_process.pollen')) }
  let(:definition) { Swarm::ProcessDefinition.create_from_pollen(pollen) }
  subject { definition.launch_process(:workitem => {}) }

  context "with subprocess expression" do
    it "runs subprocess inline with main process" do
      Swarm::ProcessDefinition.create_from_pollen(File.read(fixtures_path.join("trace_process.pollen")))
      subject.wait_until_finished
      expect(subject.reload!.workitem["traced"]).to eq([
        "prologue",
        "first string",
        "second string",
        "third string",
        "fourth string",
        "final string",
        "epilogue"
      ])
    end
  end
end
