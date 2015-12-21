require_relative "job"

module Swarm
  module Engine
    module Volatile
      class Queue < Swarm::Engine::Queue
        attr_reader :jobs, :workers

        class << self
          def repository
            @repository ||= {}
          end

          def find_or_create(name)
            repository[name] ||= new(name: name)
          end
        end

        def initialize(name:)
          @name = name
          @workers = []
          @jobs = []
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
          sleep(delay_time += 0.01) until jobs.count > 0
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
          @jobs = []
        end

        def worker_count
          @workers.count
        end

        def add_worker(worker)
          @workers << worker
        end

        def idle?
          jobs.empty?
        end
      end
    end
  end
end