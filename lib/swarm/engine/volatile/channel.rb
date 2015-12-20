require_relative "job"

module Swarm
  module Engine
    module Volatile
      class Channel < Swarm::Engine::Channel
        attr_reader :jobs, :workers

        class << self
          def repository
            @repository ||= {}
          end

          def find_or_create(name)
            repository[name] ||= new
          end
        end

        def initialize
          @workers = []
          @jobs = []
        end

        def put(data)
          new_job = Job.new(channel: self, data: data)
          jobs << new_job
          new_job
        end

        def reserve(client)
          sleep(0.01) until jobs.count > 0
          index = jobs.index { |job| job.available? }
          raise JobNotFoundError unless index
          job = jobs[index]
          job.reserve!(client)
          job
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

        def empty?
          jobs.empty?
        end
      end
    end
  end
end