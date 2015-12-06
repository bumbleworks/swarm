RSpec.describe Swarm::Engine::Worker do
  subject { described_class.new }
  let(:worker_job) { described_class::Job.new(command: "spew", metadata: {}, hive: hive) }

  before(:each) {
    allow(work_queue).to receive(:clone).and_return(work_queue)
    allow(described_class::Job).to receive(:from_queued_job).
      with(:a_queued_job, hive: hive).
      and_return(worker_job)
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
    it "returns true if running variable true" do
      subject.instance_variable_set(:@running, true)
      expect(subject).to be_running
    end

    it "returns false if running variable false" do
      subject.instance_variable_set(:@running, false)
      expect(subject).not_to be_running
    end

    it "returns false by default" do
      expect(subject).not_to be_running
    end
  end

  describe "#run!" do
    it "processes jobs while running" do
      expect(subject).to receive(:process_next_job).twice
      expect(subject).to receive(:running?).and_return(true, true, false)
      subject.run!
    end
  end

  describe "#work_on" do
    it "pulls command and metadata from JSON job body and runs the command" do
      expect(worker_job).to receive(:run_command!)
      subject.work_on(:a_queued_job)
    end

    it "stops worker and cleans up if job contains special 'stop_worker' command" do
      allow(worker_job).to receive(:stop_job?).and_return(true)
      expect(work_queue).to receive(:remove_worker).with(subject, :stop_job => :a_queued_job).ordered
      expect(subject).to receive(:stop!).ordered
      subject.work_on(:a_queued_job)
    end
  end

  describe "#process_next_job" do
    it "reserves, works on, deletes, and cleans up the next job in the queue" do
      allow(work_queue).to receive(:reserve_job).and_return(:the_job)
      expect(subject).to receive(:work_on).with(:the_job)
      expect(work_queue).to receive(:delete_job).with(:the_job)
      expect(work_queue).to receive(:clean_up_job).with(:the_job)
      subject.process_next_job
    end

    it "retries if job reservation fails" do
      expect(work_queue).to receive(:reserve_job).and_raise(Swarm::Engine::WorkQueue::JobReservationFailed).twice
      expect(work_queue).to receive(:reserve_job).and_return(:the_job)
      expect(subject).to receive(:work_on).with(:the_job)
      expect(work_queue).to receive(:delete_job).with(:the_job)
      expect(work_queue).to receive(:clean_up_job).with(:the_job)
      subject.process_next_job
    end

    it "does nothing if non-retry error occurs while reserving" do
      expect(work_queue).to receive(:reserve_job).and_raise(ArgumentError)
      expect(subject).to receive(:work_on).never
      expect(work_queue).to receive(:bury_job).never
      subject.process_next_job
    end

    it "buries and cleans up job if other error occurs while working" do
      expect(work_queue).to receive(:reserve_job).and_return(:the_job)
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