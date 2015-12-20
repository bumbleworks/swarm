RSpec.describe Swarm::Engine::Beanstalk::Channel do
  let(:job) { instance_double(Beaneater::Job) }
  subject { described_class.new(:tube => "dummy_queue") }

  describe "#put" do
    it "puts JSON version of job into queue" do
      expect(subject.tube).to receive(:put).with({ :a => :b }.to_json).
        and_return(:the_job)
      expect(subject.put({ :a => :b })).to eq(:the_job)
    end
  end

  describe "#reserve" do
    shared_examples "a job reservation failure" do |reservation_exception, new_exception|
      it "raises #{new_exception} when #{reservation_exception.class} raised" do
        allow(subject.tube).to receive(:reserve).and_raise(reservation_exception)
        expect {
          subject.reserve(:a_client)
        }.to raise_error(new_exception)
      end
    end

    it "reserves next job in tube" do
      allow(subject.tube).to receive(:reserve).and_return(:the_job)
      expect(subject.reserve(:a_client)).to eq(:the_job)
    end

    it_behaves_like "a job reservation failure", Beaneater::JobNotReserved.new, Swarm::Engine::Job::AlreadyReservedError
    it_behaves_like "a job reservation failure", Beaneater::NotFoundError.new(nil, nil), described_class::JobNotFoundError
    it_behaves_like "a job reservation failure", Beaneater::TimedOutError.new(nil, nil), described_class::JobNotFoundError

    it "does not rescue non-job-reservation errors" do
      allow(subject.tube).to receive(:reserve).and_raise(ArgumentError.new("phosh"))
      expect {
        subject.reserve(:a_client)
      }.to raise_error(ArgumentError, "phosh")
    end
  end

  describe "#worker_count" do
    it "returns count of tube watchers from stats" do
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

  describe "#empty?" do
    it "returns true if tube has no ready jobs" do
      expect(subject.tube).to receive(:peek).with(:ready).
        and_return(nil)
      expect(subject).to be_empty
    end

    it "returns false if tube has ready jobs" do
      expect(subject.tube).to receive(:peek).with(:ready).
        and_return(:a_job)
      expect(subject).not_to be_empty
    end
  end
end