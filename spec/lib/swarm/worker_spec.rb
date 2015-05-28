describe Swarm::Worker do
  let(:jobs) { double(Beaneater::Jobs) }
  let(:beaneater) { double(Beaneater, :jobs => jobs) }
  subject { described_class.new(hive: hive) }

  before(:each) {
    allow(work_queue).to receive(:clone).and_return(work_queue)
    allow(work_queue).to receive(:beaneater).and_return(beaneater)
  }

  describe "#register_processor" do
    it "sets up processor" do
      allow(jobs).to receive(:register).with("swarm-test-queue").and_yield(:a_job)
      expect(subject).to receive(:work_on).with(:a_job)
      subject.register_processor
    end
  end

  describe "#run!" do
    it "registers processor and starts processing jobs" do
      expect(subject).to receive(:register_processor)
      expect(jobs).to receive(:process!)
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
      expect(subject).to receive(:clean_up_stop_job).ordered
      expect(subject).to receive(:stop!).ordered
      subject.work_on(job)
    end
  end

  describe "#clean_up_stop_job" do
    it "deletes the stop job if we're the only one watching" do
      job_double = double(Beaneater::Job)
      allow(work_queue).to receive(:worker_count).and_return(1)
      expect(job_double).to receive(:delete)
      subject.clean_up_stop_job(job_double)
    end

    it "releases the stop job if others are watching" do
      job_double = double(Beaneater::Job)
      allow(work_queue).to receive(:worker_count).and_return(2)
      expect(job_double).to receive(:release).with(:delay => 1)
      subject.clean_up_stop_job(job_double)
    end
  end

  describe "#stop!" do
    it "raises Beaneater::AbortProcessingError to signal Beaneater to break from cycle" do
      expect {
        subject.stop!
      }.to raise_error(Beaneater::AbortProcessingError)
    end
  end
end