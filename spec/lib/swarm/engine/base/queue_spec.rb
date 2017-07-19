RSpec.describe Swarm::Engine::Queue do
  let(:job) { instance_double(Swarm::Engine::Job) }
  subject { described_class.new(name: "a queue") }

  it_behaves_like "an interface with required implementations",
    {
      prepare_for_work: 1,
      add_job: 1,
      reserve_job: 1,
      clear: 0,
      idle?: 0,
      worker_count: 0
    }

  describe "#delete_job" do
    it "delegates #delete to given job" do
      expect(job).to receive(:delete)
      subject.delete_job(job)
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
end
