class ThinkingSphinx::Deltas::ResqueDelta::CoreIndex

  def sphinx_indices
    unless @sphinx_indices
      @ts_config ||= ThinkingSphinx::Configuration.instance
      @ts_config.preload_indices
      @sphinx_indices = @ts_config.configuration.indices.collect { |i| i.name }
      # The collected indices look like:
      # ["foo_core", "foo_delta", "foo", "bar_core", "bar_delta", "bar"]
      @sphinx_indices.reject! { |i| i =~ /_(core|delta)$/}
      # Now we have:
      # ["foo", "bar"]
    end
    @sphinx_indices
  end

  # Public: Lock a delta index against indexing or new index jobs.
  #
  # index_name - The String index prefix.
  #
  # Examples
  #
  #   lock_delta('foo')
  #
  # Returns nothing.
  def lock_delta(index_name)
    ThinkingSphinx::Deltas::ResqueDelta.lock("#{index_name}_delta")
  end

  # Public: Unlock a delta index for indexing or new index jobs.
  #
  # index_name - The String index prefix.
  #
  # Examples
  #
  #   unlock_delta('foo')
  #
  # Returns nothing.
  def unlock_delta(index_name)
    ThinkingSphinx::Deltas::ResqueDelta.unlock("#{index_name}_delta")
  end

  # Public: Lock all delta indexes against indexing or new index jobs.
  #
  # Returns nothing.
  def lock_deltas
    sphinx_indices.each { |index_name| lock_delta(index_name) }
  end

  # Public: Unlock all delta indexes for indexing or new index jobs.
  #
  # Returns nothing.
  def unlock_deltas
    sphinx_indices.each { |index_name| unlock_delta(index_name) }
  end

  # Public: Index all indices while locking each delta as we index the corresponding core index.
  #
  # Returns true on success; false on failure.
  def smart_index(opts = {})
    verbose = opts.fetch(:verbose, true)
    verbose = false if ENV['SILENT'] == 'true'

    # Load config like ts:in.
    unless ENV['INDEX_ONLY'] == 'true'
      puts "Generating Configuration to #{ts_config.config_file}" if verbose
      ts_config.build
    end
    FileUtils.mkdir_p(ts_config.searchd_file_path)

    # Index each core, one at a time. Wrap with delta locking logic.
    index_prefixes.each do |index_name|
      ret = nil

      with_delta_index_lock(index_name) do
        ThinkingSphinx::Deltas::ResqueDelta.prepare_for_core_index(index_name)
        ts_config.controller.index("#{index_name}_core", :verbose => verbose)
        ret = $?
      end

      return false if ret.to_i != 0

      Resque.enqueue(
        ThinkingSphinx::Deltas::ResqueDelta::DeltaJob,
        "#{index_name}_delta"
      )
    end

    true
  end

  # Public: Wraps the passed block with a delta index lock
  #
  # index_name - The String index prefix.
  #
  # Examples
  #
  #   with_delta_index_lock('foo')
  #
  # Returns nothing.
  def with_delta_index_lock(index_name)
    lock_delta(index_name)
    yield
    unlock_delta(index_name)
  end

  private

  def ts_config
    ThinkingSphinx::Deltas::ResqueDelta::IndexUtils.ts_config
  end

  def index_prefixes
    ThinkingSphinx::Deltas::ResqueDelta::IndexUtils.index_prefixes
  end
end
