require 'thinking_sphinx/deltas/resque_delta'

namespace :thinking_sphinx do

  # Return a list of index prefixes (i.e. without "_core"/"_delta").
  def sphinx_indexes
    unless @sphinx_indexes
      @ts_config ||= ThinkingSphinx::Configuration.instance
      @sphinx_indexes = @ts_config.configuration.indexes.collect { |i| i.name }
      # The collected indexes look like:
      # ["foo_core", "foo_delta", "foo", "bar_core", "bar_delta", "bar"]
      @sphinx_indexes.reject! { |i| i =~ /_(core|delta)$/}
      # Now we have:
      # ["foo", "bar"]
    end
    @sphinx_indexes
  end

  def lock_delta(index_name)
    ThinkingSphinx::Deltas::ResqueDelta.lock("#{index_name}_delta")
  end

  def unlock_delta(index_name)
    ThinkingSphinx::Deltas::ResqueDelta.unlock("#{index_name}_delta")
  end

  desc 'Lock all delta indexes (Resque will not run indexer or place new jobs on the :ts_delta queue).'
  task :lock_deltas do
    sphinx_indexes.each { |index_name| lock_delta(index_name) }
  end

  desc 'Unlock all delta indexes.'
  task :unlock_deltas do
    sphinx_indexes.each { |index_name| unlock_delta(index_name) }
  end

  desc 'Like `rake thinking_sphinx:index`, but locks one index at a time.'
  task :smart_index => :app_env do
    # Load config like ts:in.
    @ts_config = ThinkingSphinx::Configuration.instance
    unless ENV['INDEX_ONLY'] == 'true'
      puts "Generating Configuration to #{@ts_config.config_file}"
      @ts_config.build
    end
    FileUtils.mkdir_p(@ts_config.searchd_file_path)

    # Index each core, one at a time. Wrap with delta locking logic.
    sphinx_indexes.each do |index_name|
      lock_delta(index_name)
      @ts_config.controller.index("#{index_name}_core", :verbose => true)
      ret = $?
      unlock_delta(index_name)
      exit(-1) if ret.to_i != 0
      Resque.enqueue(
        ThinkingSphinx::Deltas::ResqueDelta::DeltaJob,
        ["#{index_name}_delta"]
      )
    end
  end
end

namespace :ts do

  desc 'Like `rake thinking_sphinx:index`, but locks one index at a time.'
  task :si => 'thinking_sphinx:smart_index'
end

unless Rake::Task.task_defined?('thinking_sphinx:index')
  require 'thinking_sphinx/tasks'
end

# Ensure that indexing does not conflict with ts-resque-delta delta jobs.
Rake::Task['thinking_sphinx:index'].enhance ['thinking_sphinx:lock_deltas'] do
  Rake::Task['thinking_sphinx:unlock_deltas']
end
