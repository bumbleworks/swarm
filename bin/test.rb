#!/usr/bin/env ruby

require "bundler/setup"
require "swarm"

redis = Redis.new(:db => 15)
storage = Swarm::Storage.new(redis)
beanstalk = Beaneater.new("localhost:11300")
work_queue = beanstalk.tubes["swarm-queue"]
hive = Swarm::Hive.new(:storage => storage, :work_queue => work_queue)

json = File.read('spec/fixtures/process_definition.json')
pd = Swarm::ProcessDefinition.create_from_json(json, :hive => hive)
process = pd.launch_process({ "words" => [], "expression_ids" => [] })

require 'pry'; binding.pry