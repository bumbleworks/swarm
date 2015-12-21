RSpec.describe Swarm::Process, :process => true do
  let(:pollen) { File.read(fixture_path) }
  let(:definition) { Swarm::ProcessDefinition.create_from_pollen(pollen) }
  subject { definition.launch_process(workitem: {}) }

  context "with concurrence block" do
    let(:fixture_path) { fixtures_path.join('concurrence_process.pollen') }

    it "calls all children concurrently" do
      subject
      wait_until { Swarm::StoredWorkitem.count == 2 }
      expect(Swarm::StoredWorkitem.map(&:command)).to eq(["defer", "defer"])
    end

    it "does not proceed if not all children have replied" do
      subject
      wait_until { Swarm::StoredWorkitem.count == 2 }
      Swarm::StoredWorkitem.first.proceed
      wait_until_worker_idle
      expect(hive.traced).to be_empty
    end

    it "proceeds when all children have replied" do
      subject
      wait_until { Swarm::StoredWorkitem.count == 2 }
      Swarm::StoredWorkitem.map(&:proceed)
      wait_until { hive.traced == ["concurrence done"] }
    end
  end
end