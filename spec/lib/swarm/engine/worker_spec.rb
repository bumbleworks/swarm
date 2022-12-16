RSpec.describe Swarm::Engine::Worker do
  subject { described_class.new }
  let(:command) { described_class::Command.new(action: "spew", metadata: {}, hive: hive) }

  before(:each) {
    allow(work_queue).to receive(:prepare_for_work).with(subject).and_return(work_queue)
    allow(described_class::Command).to receive(:from_job).
      with(:a_queued_job, hive: hive).
      and_return(command)
  }

  describe "#working?" do
    it "returns true if working variable true" do
      subject.instance_variable_set(:@working, true)
      expect(subject).to be_working
    end

    it "returns false if working variable false" do
      subject.instance_variable_set(:@working, false)
      expect(subject).not_to be_working
    end

    it "returns false by default" do
      expect(subject).not_to be_working
    end
  end

  describe "#running?" do
    it "returns false by default" do
      expect(subject).not_to be_running
    end

    it "returns true if running variable true and queue exists" do
      allow(subject).to receive(:queue).and_return(:a_queue)
      subject.instance_variable_set(:@running, true)
      expect(subject).to be_running
    end

    it "returns false if running variable false" do
      allow(subject).to receive(:queue).and_return(:a_queue)
      subject.instance_variable_set(:@running, false)
      expect(subject).not_to be_running
    end

    it "returns false if no queue" do
      allow(subject).to receive(:queue).and_return(nil)
      subject.instance_variable_set(:@running, true)
      expect(subject).not_to be_running
    end
  end

  describe "#setup" do
    it "sets up a prepared work queue for worker" do
      allow(work_queue).to receive(:prepare_for_work).with(subject).and_return(:the_work_queue)
      subject.setup
      expect(subject.queue).to eq(:the_work_queue)
    end
  end

  describe "#teardown" do
    it "clears queue" do
      subject.setup
      subject.teardown
      expect(subject.queue).to be_nil
    end
  end

  describe "#run!" do
    it "sets up, processes jobs while running, and tears down" do
      expect(subject).to receive(:setup).ordered
      expect(subject).to receive(:process_next_job).twice.ordered
      expect(subject).to receive(:teardown).ordered
      allow(subject).to receive(:running?).and_return(true, true, false)
      subject.run!
    end
  end

  describe "#work_on" do
    before(:each) do
      subject.setup
    end

    it "pulls command and metadata from JSON job body and runs the command" do
      allow(subject).to receive(:running?).and_return(true)
      expect(command).to receive(:run!)
      subject.work_on(:a_queued_job)
    end

    it "stops worker and cleans up if job contains special 'stop_worker' command" do
      allow(subject).to receive(:running?).and_return(true)
      allow(command).to receive(:stop?).and_return(true)
      expect(work_queue).to receive(:remove_worker).with(subject, stop_job: :a_queued_job).ordered
      expect(subject).to receive(:stop!).ordered
      subject.work_on(:a_queued_job)
    end

    it "raises exception if not running" do
      allow(subject).to receive(:running?).and_return(false)
      expect {
        subject.work_on(:a_queued_job)
      }.to raise_error(described_class::NotRunningError)
    end
  end

  describe "#process_next_job" do
    before(:each) do
      subject.setup
    end

    it "reserves, works on, deletes, and cleans up the next job in the queue" do
      allow(work_queue).to receive(:reserve_job).with(subject).and_return(:the_job)
      expect(subject).to receive(:work_on).with(:the_job)
      expect(work_queue).to receive(:delete_job).with(:the_job)
      expect(work_queue).to receive(:clean_up_job).with(:the_job)
      subject.process_next_job
    end

    it "retries if job reservation fails" do
      expect(work_queue).to receive(:reserve_job).with(subject).and_raise(Swarm::Engine::Queue::JobReservationFailed).twice
      expect(work_queue).to receive(:reserve_job).with(subject).and_return(:the_job)
      expect(subject).to receive(:work_on).with(:the_job)
      expect(work_queue).to receive(:delete_job).with(:the_job)
      expect(work_queue).to receive(:clean_up_job).with(:the_job)
      subject.process_next_job
    end

    it "does nothing if non-retry error occurs while reserving" do
      expect(work_queue).to receive(:reserve_job).with(subject).and_raise(ArgumentError)
      expect(subject).to receive(:work_on).never
      expect(work_queue).to receive(:bury_job).never
      subject.process_next_job
    end

    it "buries and cleans up job if other error occurs while working" do
      expect(work_queue).to receive(:reserve_job).with(subject).and_return(:the_job)
      expect(subject).to receive(:work_on).with(:the_job).and_raise(ArgumentError)
      expect(work_queue).to receive(:bury_job).with(:the_job)
      expect(work_queue).to receive(:clean_up_job).with(:the_job)
      subject.process_next_job
    end
  end

  describe "#stop!" do
    it "sets running to false and clears current job" do
      subject.instance_variable_set(:@running, true)
      subject.instance_variable_set(:@current_job, :a_job)
      subject.stop!
      expect(subject).not_to be_running
      expect(subject.instance_variable_get(:@current_job)).to be_nil
    end
  end
end
