require 'ts/deltas/resque_delta'

namespace :ts do
  desc 'Lock all delta indices (Resque will not run indexer or place new jobs on the :ts_delta queue).'
  task :lock_deltas do
    ThinkingSphinx::Deltas::ResqueDelta::CoreIndex.new.lock_deltas
  end

  desc 'Unlock all delta indices.'
  task :unlock_deltas do
    ThinkingSphinx::Deltas::ResqueDelta::CoreIndex.new.unlock_deltas
  end

  desc 'Like `rake ts:index`, but locks one index at a time.'
  task :smart_index => :app_env do
    ret = ThinkingSphinx::Deltas::ResqueDelta::CoreIndex.new.smart_index

    abort("Indexing failed.") if ret != true
  end
end

namespace :ts do
  desc 'Like `rake ts:index`, but locks one index at a time.'
  task :si => 'ts:smart_index'
end

unless Rake::Task.task_defined?('ts:index')
  require 'ts/tasks'
end

# Ensure that indexing does not conflict with ts-resque-delta delta jobs.
Rake::Task['ts:index'].enhance ['ts:lock_deltas'] do
  Rake::Task['ts:unlock_deltas'].invoke
end

Rake::Task['ts:reindex'].enhance ['ts:lock_deltas'] do
  Rake::Task['ts:unlock_deltas'].invoke
end
