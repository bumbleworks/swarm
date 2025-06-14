# frozen_string_literal: true

RSpec.describe Swarm::Process, process: true do
  let(:json) { File.read(fixture_path) }
  let(:definition) { Swarm::ProcessDefinition.create_from_json(json) }
  subject { definition.launch_process(workitem: { "ghosts" => "fake" }) }

  context "with conditional blocks" do
    let(:fixture_path) { fixtures_path.join('conditional_process.json') }

    it "only executes blocks where conditional is true" do
      subject
      wait_until do hive.traced.include?("and that is a fact") end
      expect(hive.traced).to eq([
        "oh",
        "ha ha",
        "no such thing as ghosts",
        "they don't exist yo",
        "so you can relax",
        "and that is a fact"
      ])
    end
  end
end
