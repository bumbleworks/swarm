describe Swarm::Worker do
  subject { described_class.new(hive: hive) }

  before(:each) {
    allow(work_queue).to receive(:clone).and_return(work_queue)
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

  describe "#run!" do
    it "processes jobs while working" do
      expect(subject).to receive(:process_next_job).twice
      expect(subject).to receive(:working?).and_return(true, true, false)
      subject.run!
    end
  end

  describe "#run_command!" do
    it "fetches object from metadata and sends given command" do
      hive_dweller = double
      allow(hive).to receive(:fetch).with("SpecialHat", "9876").and_return(hive_dweller)
      expect(hive_dweller).to receive(:_grapple)
      subject.run_command!("grapple", { "type" => "SpecialHat", "id" => "9876" })
    end
  end

  describe "#work_on" do
    it "pulls command and metadata from JSON job body and runs the command" do
      job = double(:body => { "command" => "grapple", "metadata" => "the_metadata" }.to_json)
      expect(subject).to receive(:run_command!).with("grapple", "the_metadata")
      subject.work_on(job)
    end

    it "stops worker and cleans up if job contains special 'stop_worker' command" do
      job = double(:body => { "command" => "stop_worker" }.to_json)
      expect(work_queue).to receive(:remove_worker).with(subject, :stop_job => job).ordered
      expect(subject).to receive(:stop!).ordered
      subject.work_on(job)
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
      expect(work_queue).to receive(:reserve_job).and_raise(Swarm::WorkQueue::JobReservationFailed).twice
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
    it "sets working to false and clears current job" do
      subject.instance_variable_set(:@working, true)
      subject.instance_variable_set(:@current_job, :a_job)
      subject.stop!
      expect(subject).not_to be_working
      expect(subject.instance_variable_get(:@current_job)).to be_nil
    end
  end
end