# frozen_string_literal: true

require "swarm/observers/logger"

RSpec.describe Swarm::Observers::Logger do
  let(:command) { Swarm::Engine::Worker::Command.new(action: "brog", metadata: { foo: "ber" }) }
  subject { described_class.new(command) }

  describe "#before_action" do
    it "sets initial workitem to object's workitem" do
      allow(command).to receive(:object).and_return(double(workitem: "the workitem"))
      subject.before_action
      expect(subject.initial_workitem).to eq("the workitem")
    end

    it "does nothing if no object" do
      allow(command).to receive(:object).and_return(nil)
      subject.before_action
      expect(subject.initial_workitem).to be_nil
    end
  end

  describe "#object_string" do
    it "returns No object if object is nil" do
      expect(subject.object_string).to eq("No object")
    end

    it "returns expression representation if object is expression" do
      expression = Swarm::Expression.new(position: [0, 4])
      allow(expression).to receive(:command).and_return("jump")
      allow(expression).to receive(:arguments).and_return({ args: :foo })
      allow(expression).to receive(:reload!)
      allow(command).to receive(:object).and_return(expression)
      expect(subject.object_string).to eq("[0, 4]: jump {:args=>:foo}")
    end

    it "returns process definition name if object is process" do
      process = Swarm::Process.new
      allow(process).to receive(:process_definition_name).and_return("great_process")
      allow(process).to receive(:reload!)
      allow(command).to receive(:object).and_return(process)
      expect(subject.object_string).to eq("great_process")
    end

    it "does not add workitem to end of string if it has not changed" do
      process = Swarm::Process.new
      allow(process).to receive(:process_definition_name).and_return("great_process")
      allow(process).to receive(:reload!)
      allow(process).to receive(:workitem).and_return("initial")
      allow(command).to receive(:object).and_return(process)
      subject.before_action
      expect(subject.object_string).to eq("great_process")
    end

    it "adds workitem to end of string if it has changed" do
      process = Swarm::Process.new
      allow(process).to receive(:process_definition_name).and_return("great_process")
      allow(process).to receive(:reload!)
      allow(process).to receive(:workitem).and_return("initial")
      allow(command).to receive(:object).and_return(process)
      subject.before_action
      allow(process).to receive(:workitem).and_return("the new huzzah")
      expect(subject.object_string).to eq("great_process; the new huzzah")
    end
  end

  describe "#log_entry" do
    around(:each) do |example|
      Timecop.freeze
      example.run
      Timecop.return
    end

    it "returns a string with timestamp, action, and the object" do
      allow(subject).to receive(:object_string).and_return("my object string")
      expect(subject.log_entry).to eq(
        "[#{Time.now}]: brog; my object string"
      )
    end
  end

  describe "#after_action" do
    around(:each) do |example|
      previous = $stdout
      $stdout = StringIO.new
      example.run
      $stdout = previous
    end

    it "puts the log_entry" do
      allow(subject).to receive(:log_entry).and_return("the entry!")
      subject.after_action
      expect($stdout.string).to eq("the entry!\n")
    end
  end
end
