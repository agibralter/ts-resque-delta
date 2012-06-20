class ThinkingSphinx::Deltas::ResqueDelta < ThinkingSphinx::Deltas::DefaultDelta
  module FlagAsDeletedSet
    extend self

    def set_name(core_name)
      "#{ThinkingSphinx::Deltas::ResqueDelta.job_prefix}:flag.deleted:#{core_name}:set"
    end

    def temp_name(core_name)
      "#{ThinkingSphinx::Deltas::ResqueDelta.job_prefix}:flag.deleted:#{core_name}:temp"
    end

    def processing_name(core_name)
      "#{ThinkingSphinx::Deltas::ResqueDelta.job_prefix}:flag.deleted:#{core_name}:processing"
    end

    def add(core_name, document_id)
      Resque.redis.sadd(set_name(core_name), document_id)
    end

    def clear!(core_name)
      Resque.redis.del(set_name(core_name))

      #Clear processing set as well
      delta_name = ThinkingSphinx::Deltas::ResqueDelta::IndexUtils.core_to_delta(core_name)
      ThinkingSphinx::Deltas::ResqueDelta::DeltaJob.around_perform_lock(delta_name) do
        Resque.redis.del(processing_name(core_name))
      end
    end

    def clear_all!
      ThinkingSphinx::Deltas::ResqueDelta::IndexUtils.core_indices.each do |core_index|
        clear!(core_index)
      end
    end

    def get_subset_for_processing(core_name)
      # Use a transaction to keep from losing set members if interrupted
      Resque.redis.multi do
        # Copy set to temp
        Resque.redis.sunionstore temp_name(core_name), set_name(core_name)
        # Store (set - temp) into set.  This removes all items we copied into temp from set.
        Resque.redis.sdiffstore set_name(core_name), set_name(core_name), temp_name(core_name)
        # Merge processing and temp together and store into processing.
        Resque.redis.sunionstore processing_name(core_name), processing_name(core_name), temp_name(core_name)

        Resque.redis.del temp_name(core_name)
      end
    end

    def processing_members(core_name)
      Resque.redis.smembers(processing_name(core_name)).collect(&:to_i)
    end

    def clear_processing(core_name)
      Resque.redis.del(processing_name(core_name))
    end
  end
end
