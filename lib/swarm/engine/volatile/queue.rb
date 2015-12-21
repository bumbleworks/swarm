require_relative "job"

module Swarm
  module Engine
    module Volatile
      class Queue < Swarm::Engine::Queue
        Tube = Struct.new(:jobs, :workers)

        extend Forwardable
        def_delegators :tube, :jobs, :workers

        attr_reader :tube, :name

        class << self
          def tubes
            @tubes ||= {}
          end

          def get_tube(name)
            tubes[name] ||= Tube.new([], [])
          end
        end

        def initialize(name:)
          @name = name
          @tube = self.class.get_tube(name)
        end

        def prepare_for_work(worker)
          add_worker(worker) unless workers.include?(worker)
          self
        end

        def add_job(data)
          new_job = Job.new(queue: self, data: data)
          jobs << new_job
          new_job
        end

        def wait_for_job
          delay_time = 0
          until jobs.count > 0
            delay_time += 0.01 unless delay_time > 1.0
            sleep(delay_time)
          end
        end

        def reserve_job(worker)
          wait_for_job
          index = jobs.index { |job| job.available? }
          raise JobNotFoundError unless index
          job = jobs[index]
          job.reserve!(worker)
          job
        rescue JobNotFoundError, Job::AlreadyReservedError
          raise JobReservationFailed
        end

        def delete_job(job_to_delete)
          jobs.delete_if { |job| job == job_to_delete }
        end

        def has_job?(job_to_find)
          jobs.any? { |job| job == job_to_find }
        end

        def clear
          tube.jobs = []
        end

        def worker_count
          workers.count
        end

        def add_worker(worker)
          workers << worker
        end

        def idle?
          jobs.empty?
        end
      end
    end
  end
end