RSpec.describe Swarm::Engine::Beanstalk::Queue do
  let(:job) { instance_double(Beaneater::Job) }
  subject { described_class.new(:name => "dummy_queue") }

  describe "#add_job" do
    it "puts JSON version of job into queue" do
      expect(subject.tube).to receive(:put).with({ :a => :b }.to_json).
        and_return(:the_job)
      expect(subject.add_job({ :a => :b })).to eq(:the_job)
    end
  end

  describe "#reserve_job" do
    shared_examples "a job reservation failure" do |reservation_exception|
      it "raises JobReservationFailed exception when #{reservation_exception.class} raised" do
        allow(subject.tube).to receive(:reserve).and_raise(reservation_exception)
        expect {
          subject.reserve_job(:a_worker)
        }.to raise_error(described_class::JobReservationFailed)
      end
    end

    it "reserves next job in tube" do
      allow(subject.tube).to receive(:reserve).and_return(:the_job)
      expect(subject.reserve_job(:a_worker)).to eq(:the_job)
    end

    it_behaves_like "a job reservation failure", Beaneater::JobNotReserved.new
    it_behaves_like "a job reservation failure", Beaneater::NotFoundError.new(nil, nil)
    it_behaves_like "a job reservation failure", Beaneater::TimedOutError.new(nil, nil)

    it "does not rescue non-job-reservation errors" do
      allow(subject.tube).to receive(:reserve).and_raise(ArgumentError.new("phosh"))
      expect {
        subject.reserve_job(:a_worker)
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
    it "returns count from tube" do
      allow(subject.tube).to receive(:stats).and_return(double(:current_watching => 34))
      expect(subject.worker_count).to eq(34)
    end
  end

  describe "#clear" do
    it "clears tube" do
      expect(subject.tube).to receive(:clear)
      subject.clear
    end
  end

  describe "#prepare_for_work" do
    it "returns clone with worker assigned" do
      clone = subject.prepare_for_work(:the_worker)
      expect(clone).not_to be(subject)
      expect(clone.name).to eq(subject.name)
      expect(clone.address).to eq(subject.address)
      expect(clone.worker).to eq(:the_worker)
    end
  end

  describe "#idle?" do
    it "returns true if tube has no ready jobs" do
      expect(subject.tube).to receive(:peek).with(:ready).
        and_return(nil)
      expect(subject).to be_idle
    end

    it "returns false if tube has ready jobs" do
      expect(subject.tube).to receive(:peek).with(:ready).
        and_return(:a_job)
      expect(subject).not_to be_idle
    end
  end
end