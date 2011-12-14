require 'resque'
require 'thinking_sphinx'

require 'thinking_sphinx/deltas/resque_delta/flag_as_deleted_set'
require 'thinking_sphinx/deltas/resque_delta/index_utils'

# Delayed Deltas for Thinking Sphinx, using Resque.
#
# This documentation is aimed at those reading the code. If you're looking for
# a guide to Thinking Sphinx and/or deltas, I recommend you start with the
# Thinking Sphinx site instead - or the README for this library at the very
# least.
#
# @author Patrick Allan
# @see http://ts.freelancing-gods.com Thinking Sphinx
#
class ThinkingSphinx::Deltas::ResqueDelta < ThinkingSphinx::Deltas::DefaultDelta
  def self.job_types
    [
      ThinkingSphinx::Deltas::ResqueDelta::DeltaJob
    ]
  end
  
  def self.job_prefix
    'ts-delta'
  end
  
  # LTRIM + LPOP deletes all items from the Resque queue without loading it
  # into client memory (unlike Resque.dequeue).
  # WARNING: This will clear ALL jobs in any queue used by a ResqueDelta job.
  # If you're sharing a queue with other jobs they'll be deleted!
  def self.clear_thinking_sphinx_queues
    job_types.collect { |c| c.instance_variable_get(:@queue) }.uniq.each do |q|
      Resque.redis.ltrim("queue:#{q}", 0, 0)
      Resque.redis.lpop("queue:#{q}")
    end
  end

  # Clear both the resque queues and any other state maintained in redis
  def self.clear!
    self.clear_thinking_sphinx_queues

    FlagAsDeletedSet.clear_all!
  end

  # Use simplistic locking.  We're assuming that the user won't run more than one
  # `rake ts:si` or `rake ts:in` task at a time.
  def self.lock(index_name)
    Resque.redis.set("#{job_prefix}:index:#{index_name}:locked", 'true')
  end

  def self.unlock(index_name)
    Resque.redis.del("#{job_prefix}:index:#{index_name}:locked")
  end

  def self.locked?(index_name)
    Resque.redis.get("#{job_prefix}:index:#{index_name}:locked") == 'true'
  end

  def self.prepare_for_core_index(index_name)
    core = "#{index_name}_core"
    delta = "#{index_name}_delta"

    FlagAsDeletedSet.clear!(core)

    #clear delta jobs
    # dequeue is fast for jobs with arguments
    Resque.dequeue(ThinkingSphinx::Deltas::ResqueDelta::DeltaJob, delta)
  end

  # Adds a job to the queue for processing the given model's delta index. A job
  # for hiding the instance in the core index is also created, if an instance is
  # provided.
  #
  # Neither job will be queued if updates or deltas are disabled, or if the 
  # instance (when given) is not toggled to be in the delta index. The first two
  # options are controlled via ThinkingSphinx.updates_enabled? and
  # ThinkingSphinx.deltas_enabled?.
  #
  # @param [Class] model the ActiveRecord model to index.
  # @param [ActiveRecord::Base] instance the instance of the given model that
  #   has changed. Optional.
  # @return [Boolean] true
  #
  def index(model, instance = nil)
    return true if skip?(instance)
    model.delta_index_names.each do |delta|
      next if self.class.locked?(delta)
      Resque.enqueue(
        ThinkingSphinx::Deltas::ResqueDelta::DeltaJob,
        delta
      )
    end
    if instance
      model.core_index_names.each do |core|
        FlagAsDeletedSet.add(core, instance.sphinx_document_id)
      end
    end
    true
  end

  private

  # Checks whether jobs should be enqueued. Only true if updates and deltas are
  # enabled, and the instance (if there is one) is toggled.
  #
  # @param [ActiveRecord::Base, NilClass] instance
  # @return [Boolean]
  #
  def skip?(instance)
    !ThinkingSphinx.updates_enabled? ||
    !ThinkingSphinx.deltas_enabled?  ||
    (instance && !toggled(instance))
  end
end

require 'thinking_sphinx/deltas/resque_delta/delta_job'
require 'thinking_sphinx/deltas/resque_delta/core_index'
