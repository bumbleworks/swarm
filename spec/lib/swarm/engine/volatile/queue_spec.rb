RSpec.describe Swarm::Engine::Volatile::Queue do
  let(:job) { instance_double(Swarm::Engine::Volatile::Job) }
  subject { described_class.new(:name => "dummy_queue") }

  describe ".find_or_create" do
    it "returns queue from repository if name already registered" do
      allow(described_class).to receive(:repository).
        and_return({ :foo => :the_queue })
      expect(described_class.find_or_create(:foo)).to eq(:the_queue)
    end

    it "adds new instance to repository and returns it if name not already registered" do
      repository_hash = {}
      allow(described_class).to receive(:new).
        and_return(:famous_instance)
      allow(described_class).to receive(:repository).
        and_return(repository_hash)
      expect(described_class.find_or_create("foo")).to eq(:famous_instance)
      expect(repository_hash["foo"]).to eq(:famous_instance)
    end
  end

  describe ".repository" do
    around(:each) do |example|
      old_repository = described_class.repository
      example.run
      described_class.instance_variable_set(:@repository, old_repository)
    end

    it "persists a collection at the class level" do
      described_class.repository[:foo] = "bar"
      expect(described_class.repository[:foo]).to eq("bar")
    end
  end

  describe "#add_job" do
    it "adds new job with given data to job list" do
      allow(Swarm::Engine::Volatile::Job).to receive(:new).
        with(queue: subject, data: "holo").
        and_return(:a_job)
      subject.add_job("holo")
      expect(subject.jobs).to eq([:a_job])
    end
  end

  describe "#reserve_job" do
    it "raises JobReservationFailed exception when no jobs available" do
      allow(subject).to receive(:jobs).and_return([double(:available? => false)])
      expect {
        subject.reserve_job(:a_worker)
      }.to raise_error(described_class::JobReservationFailed)
    end

    it "raises JobReservationFailed exception when job already reserved" do
      job = double(:available? => true)
      allow(subject).to receive(:jobs).and_return([job])
      allow(job).to receive(:reserve!).with(:a_worker).and_raise(Swarm::Engine::Job::AlreadyReservedError)
      expect {
        subject.reserve_job(:a_worker)
      }.to raise_error(described_class::JobReservationFailed)
    end

    it "reserves first available job with given client and returns job" do
      jobs = [
        double(:available? => false),
        double(:available? => true),
        double(:available? => true)
      ]
      allow(subject).to receive(:jobs).and_return(jobs)
      expect(jobs[1]).to receive(:reserve!).with(:a_worker)
      expect(subject.reserve_job(:a_worker)).to eq(jobs[1])
    end

    it "does not rescue non-job-reservation errors" do
      allow(subject).to receive(:jobs).and_raise(ArgumentError.new("phosh"))
      expect {
        subject.reserve_job(:a_worker)
      }.to raise_error(ArgumentError, "phosh")
    end
  end

  describe "#delete_job" do
    it "deletes given job from job list" do
      job1 = subject.add_job("job1")
      job2 = subject.add_job("job2")
      job3 = subject.add_job("job3")
      subject.delete_job(job2)
      expect(subject.jobs).to eq([job1, job3])
    end
  end

  describe "#has_job?" do
    it "returns true if given job in job list" do
      allow(subject).to receive(:jobs).and_return([:job1, :job2])
      expect(subject.has_job?(:job1)).to eq(true)
    end

    it "returns false if given job not in job list" do
      allow(subject).to receive(:jobs).and_return([:job1, :job2])
      expect(subject.has_job?(:job3)).to eq(false)
    end
  end

  describe "#bury_job" do
    it "buries given job if exists" do
      allow(job).to receive(:exists?).and_return(true)
      expect(job).to receive(:bury)
      subject.bury_job(job)
    end

    it "does not bury given job if does not exist" do
      allow(job).to receive(:exists?).and_return(false)
      expect(job).not_to receive(:bury)
      subject.bury_job(job)
    end
  end

  describe "#clean_up_job" do
    it "buries given job if exists and is reserved" do
      allow(job).to receive(:exists?).and_return(true)
      allow(job).to receive(:reserved?).and_return(true)
      expect(job).to receive(:bury)
      subject.clean_up_job(job)
    end

    it "does not clean up given job if exists but not reserved" do
      allow(job).to receive(:exists?).and_return(true)
      allow(job).to receive(:reserved?).and_return(false)
      expect(job).not_to receive(:bury)
      subject.clean_up_job(job)
    end

    it "does not clean up given job if does not exist" do
      allow(job).to receive(:exists?).and_return(false)
      expect(job).not_to receive(:bury)
      subject.clean_up_job(job)
    end
  end

  describe "#remove_worker" do
    it "deletes stop job if no workers" do
      allow(subject).to receive(:worker_count).and_return(0)
      expect(job).to receive(:delete)
      subject.remove_worker(:a_worker, stop_job: job)
    end

    it "deletes stop job if worker count is 1" do
      allow(subject).to receive(:worker_count).and_return(1)
      expect(job).to receive(:delete)
      subject.remove_worker(:a_worker, stop_job: job)
    end

    it "releases stop job if worker count is greater than 1" do
      allow(subject).to receive(:worker_count).and_return(2)
      expect(job).to receive(:release)
      subject.remove_worker(:a_worker, stop_job: job)
    end
  end

  describe "#worker_count" do
    it "returns number of workers added to channel" do
      subject.add_worker(:one)
      subject.add_worker(:two)
      expect(subject.worker_count).to eq(2)
    end
  end

  describe "#idle?" do
    it "returns true if no jobs" do
      expect(subject).to be_idle
    end

    it "returns false if jobs" do
      subject.add_job("foo")
      expect(subject).not_to be_idle
    end
  end

  describe "#add_worker" do
    it "adds given worker to worker list" do
      subject.add_worker(:one)
      subject.add_worker(:two)
      expect(subject.workers).to match_array([:one, :two])
    end
  end

  describe "#clear" do
    it "empties job list" do
      subject.add_job("foo")
      subject.add_job("bar")
      subject.clear
      expect(subject.jobs).to be_empty
    end
  end

  describe "#prepare_for_work" do
    it "adds worker and returns self" do
      expect(subject).to receive(:add_worker).with(:the_worker)
      expect(subject.prepare_for_work(:the_worker)).to eq(subject)
    end

    it "doesn't add worker if already in list" do
      allow(subject).to receive(:workers).and_return([:the_worker])
      expect(subject).to receive(:add_worker).never
      expect(subject.prepare_for_work(:the_worker)).to eq(subject)
    end
  end
end