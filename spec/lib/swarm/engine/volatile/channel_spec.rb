RSpec.describe Swarm::Engine::Volatile::Channel do
  subject { described_class.new }

  describe "#put" do
    it "adds new job with given data to job list" do
      allow(Swarm::Engine::Volatile::Job).to receive(:new).
        with(channel: subject, data: "holo").
        and_return(:a_job)
      subject.put("holo")
      expect(subject.jobs).to eq([:a_job])
    end
  end

  describe "#reserve" do
    it "raises exception if no jobs are available" do
      allow(subject).to receive(:jobs).
        and_return([double(:available? => false)])
      expect {
        subject.reserve(:client)
      }.to raise_error(described_class::JobNotFoundError)
    end

    it "reserves first available job with given client and returns job" do
      jobs = [
        double(:available? => false),
        double(:available? => true),
        double(:available? => true)
      ]
      allow(subject).to receive(:jobs).and_return(jobs)
      expect(jobs[1]).to receive(:reserve!).with(:a_client)
      expect(subject.reserve(:a_client)).to eq(jobs[1])
    end
  end

  describe "#delete_job" do
    it "deletes given job from job list" do
      job1 = subject.put("job1")
      job2 = subject.put("job2")
      job3 = subject.put("job3")
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

  describe "#clear" do
    it "empties job list" do
      subject.put("foo")
      subject.put("bar")
      subject.clear
      expect(subject.jobs).to be_empty
    end
  end

  describe "#worker_count" do
    it "returns number of workers added to channel" do
      subject.add_worker(:one)
      subject.add_worker(:two)
      expect(subject.worker_count).to eq(2)
    end
  end

  describe "#empty?" do
    it "returns true if no jobs" do
      expect(subject).to be_empty
    end

    it "returns false if jobs" do
      subject.put("foo")
      expect(subject).not_to be_empty
    end
  end

  describe "#add_worker" do
    it "adds given worker to worker list" do
      subject.add_worker(:one)
      subject.add_worker(:two)
      expect(subject.workers).to match_array([:one, :two])
    end
  end

  describe ".find_or_create" do
    it "returns channel from repository if name already registered" do
      allow(described_class).to receive(:repository).
        and_return({ :foo => :the_channel })
      expect(described_class.find_or_create(:foo)).to eq(:the_channel)
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

  describe "#repository" do
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
end
