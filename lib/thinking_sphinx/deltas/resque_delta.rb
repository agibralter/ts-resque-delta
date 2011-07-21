require 'resque'
require 'thinking_sphinx'

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
      ThinkingSphinx::Deltas::ResqueDelta::DeltaJob,
      ThinkingSphinx::Deltas::ResqueDelta::FlagAsDeletedJob
    ]
  end
  
  def self.job_prefix
    'ts-delta'
  end
  
  # LTRIM + LPOP deletes all items from the Resque queue without loading it
  # into client memory (unlike Resque.dequeue).
  def self.cancel_thinking_sphinx_jobs
    job_types.collect { |c| c.instance_variable_get(:@queue) }.uniq.each do |q|
      Resque.redis.ltrim("queue:#{q}", 0, 0)
      Resque.redis.lpop("queue:#{q}")
    end
  end

  def self.lock(index_name)
    Resque.redis.set("#{job_prefix}:index:#{index_name}:locked", 'true')
  end

  def self.unlock(index_name)
    Resque.redis.del("#{job_prefix}:index:#{index_name}:locked")
  end

  def self.locked?(index_name)
    Resque.redis.get("#{job_prefix}:index:#{index_name}:locked") == 'true'
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
        [delta]
      )
    end
    if instance
      Resque.enqueue(
        ThinkingSphinx::Deltas::ResqueDelta::FlagAsDeletedJob,
        model.core_index_names,
        instance.sphinx_document_id
      )
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
require 'thinking_sphinx/deltas/resque_delta/flag_as_deleted_job'
