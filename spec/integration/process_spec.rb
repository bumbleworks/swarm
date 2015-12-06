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

  context "with concurrence block" do
    let(:fixture_path) { fixtures_path.join('concurrence_process.json') }

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
      wait_until_worker_idle
      expect(hive.traced).to eq(["concurrence done"])
    end
  end
end