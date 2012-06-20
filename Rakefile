#!/usr/bin/env rake
require "bundler/gem_tasks"
require 'appraisal'
require 'rspec/core/rake_task'
require 'cucumber'
require 'cucumber/rake/task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = ["-c", "--format progress"]
end

Cucumber::Rake::Task.new(:features) do |t|
end

task :all_tests => [:spec, :features]

task :default => :all_tests
