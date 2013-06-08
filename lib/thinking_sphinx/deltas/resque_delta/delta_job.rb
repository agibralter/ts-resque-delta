require 'resque-lock-timeout'

# A simple job class that processes a given index.
#
class ThinkingSphinx::Deltas::ResqueDelta::DeltaJob
  extend Resque::Plugins::LockTimeout

  @queue = :ts_delta
  @lock_timeout = 240

  # Runs Sphinx's indexer tool to process the index. Currently assumes Sphinx
  # is running.
  #
  # @param [String] index the name of the Sphinx index
  #
  def self.perform(index)
    return if skip?(index)

    ThinkingSphinx::Deltas::IndexJob.new(index).perform
  end

  # Try again later if lock is in use.
  def self.lock_failed(*args)
    Resque.enqueue(self, *args)
  end

  # Run only one DeltaJob at a time regardless of index.
  #def self.identifier(*args)
    #nil
  #end

  # This allows us to have a concurrency safe version of ts-delayed-delta's
  # duplicates_exist:
  #
  # http://github.com/freelancing-god/ts-delayed-delta/blob/master/lib/thinkin
  # g_sphinx/deltas/delayed_delta/job.rb#L47
  #
  # The name of this method ensures that it runs within around_perform_lock.
  #
  # We've leveraged resque-lock-timeout to ensure that only one DeltaJob is
  # running at a time. Now, this around filter essentially ensures that only
  # one DeltaJob of each index type can sit at the queue at once. If the queue
  # has more than one, lrem will clear the rest off.
  #
  def self.around_perform_lock1(*args)
    # Remove all other instances of this job (with the same args) from the
    # queue. Uses LREM (http://code.google.com/p/redis/wiki/LremCommand) which
    # takes the form: "LREM key count value" and if count == 0 removes all
    # instances of value from the list.
    redis_job_value = Resque.encode(:class => self.to_s, :args => args)
    Resque.redis.lrem("queue:#{@queue}", 0, redis_job_value)

    yield
  end

  protected

  def self.skip?(index)
    ThinkingSphinx::Deltas::ResqueDelta.locked?(index)
  end
end
