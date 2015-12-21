RSpec.describe Swarm::SubprocessExpression do
  subject {
    described_class.new_from_storage({
      :id => 'foo',
      :workitem => { 'foo' => 'bar' },
      :process_id => '123',
      :parent_id => '456'
    })
  }

  before(:each) do
    allow(subject).to receive(:node).and_return(["subprocess", {"name" => "some_process"}, []])
  end

  describe "#work" do
    it "launches subprocess with parent_expression_id" do
      process_definition = double(Swarm::ProcessDefinition)
      expect(process_definition).to receive(:launch_process).
        with(workitem: { "foo" => "bar" }, parent_expression_id: "foo")
      allow(Swarm::ProcessDefinition).to receive(:find_by_name).
        with("some_process").
        and_return(process_definition)
      subject.work
    end

    it "raises exception if no process found by name" do
      allow(Swarm::ProcessDefinition).to receive(:find_by_name).
        with("some_process").
        and_return(nil)
      expect {
        subject.work
      }.to raise_error(Swarm::ProcessDefinition::RecordNotFoundError)
    end
  end

  describe "#move_on_from" do
    it "sets the workitem to the subprocess's workitem and replies" do
      process = instance_double(Swarm::Process, :workitem => "a_new_workitem")
      expect(subject).to receive(:reply)
      subject.move_on_from(process)
      expect(subject.workitem).to eq("a_new_workitem")
    end
  end
end