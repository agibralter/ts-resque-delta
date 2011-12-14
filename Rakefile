#!/usr/bin/env rake
require "bundler/gem_tasks"
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  # Define options in .rspec so they run with guard as well
#  t.rspec_opts = ["-c"]
end

task :default => :spec
