RSpec.describe Swarm::Engine::Volatile::Queue do
  let(:channel) { Swarm::Engine::Volatile::Channel.new }
  let(:job) { instance_double(Swarm::Engine::Volatile::Job) }
  subject { described_class.new(:name => "dummy_queue") }

  describe ".new" do
    it "connects to channel with given name and adds self as worker" do
      allow(Swarm::Engine::Volatile::Channel).to receive(:find_or_create).
        with("dummy_queue").and_return(channel)
      expect(subject.channel).to eq(channel)
      expect(channel.workers).to include(subject)
    end
  end

  describe "#add_job" do
    it "puts JSON version of job into queue" do
      expect(subject.channel).to receive(:put).with({ :a => :b })
      subject.add_job({ :a => :b })
    end
  end

  describe "#reserve_job" do
    shared_examples "a job reservation failure" do |reservation_exception|
      it "raises JobReservationFailed exception when #{reservation_exception.class} raised" do
        allow(subject.channel).to receive(:reserve).and_raise(reservation_exception)
        expect {
          subject.reserve_job
        }.to raise_error(described_class::JobReservationFailed)
      end
    end

    it "reserves next job in tube" do
      allow(subject.channel).to receive(:reserve).with(subject).and_return(:the_job)
      expect(subject.reserve_job).to eq(:the_job)
    end

    it_behaves_like "a job reservation failure", Swarm::Engine::Volatile::Channel::JobNotFoundError.new
    it_behaves_like "a job reservation failure", Swarm::Engine::Volatile::Job::AlreadyReservedError.new

    it "does not rescue non-job-reservation errors" do
      allow(subject.channel).to receive(:reserve).and_raise(ArgumentError.new("phosh"))
      expect {
        subject.reserve_job
      }.to raise_error(ArgumentError, "phosh")
    end
  end

  describe "#delete_job" do
    it "deletes given job" do
      allow(job).to receive(:delete)
      subject.delete_job(job)
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
    it "returns count of workers on channel" do
      allow(subject.channel).to receive(:worker_count).and_return(34)
      expect(subject.worker_count).to eq(34)
    end
  end

  describe "#clear" do
    it "clears channel" do
      expect(subject.channel).to receive(:clear)
      subject.clear
    end
  end

  describe "#clone" do
    it "returns new instance with same channel name" do
      clone = subject.clone
      expect(clone.name).to eq(subject.name)
    end
  end
end