# frozen_string_literal: true

require "bundler/gem_tasks"

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec, :tag) do |t, task_args|
  if task_args[:tag]
    t.rspec_opts = "--tag #{task_args[:tag]}"
  end
end

task default: [:spec]

Rake::TaskManager.record_task_metadata = true
