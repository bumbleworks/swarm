require "timeout"

RSpec.describe Swarm::Process, :type => :process do
  let(:json) { File.read(fixtures_path.join('process_definition.json')) }
  let(:definition) { Swarm::ProcessDefinition.create_from_json(json, :hive => hive) }
  subject { definition.launch_process({ "words" => [], "expression_ids" => [] }) }

  it "runs" do
    subject
    Timeout::timeout(5) do
      until subject.finished?
        sleep 0.1
      end
    end
    expect(hive.traced).to eq([
      "first string",
      "second string",
      "when will this appear",
      "who knows",
      "third string",
      "fourth string",
      "final string"
    ])
  end
end