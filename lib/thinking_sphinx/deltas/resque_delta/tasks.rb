namespace :thinking_sphinx do
  task :index do
    ThinkingSphinx::Deltas::ResqueDelta.cancel_thinking_sphinx_jobs
  end

  desc "Process stored delta index requests"
  task :resque_delta => :app_env do
    raise "TODO... for now, please just run the workers on your own and make sure to work the :ts_delta queue."
  #   require 'delayed/worker'
  #   require 'thinking_sphinx/deltas/resque_delta'
  #   
  #   Delayed::Worker.new(
  #     :min_priority => ENV['MIN_PRIORITY'],
  #     :max_priority => ENV['MAX_PRIORITY']
  #   ).start
  end

	desc "Deals with large indexes one at a time with delta locking"
	task :smart_index do
		require 'set'
		require 'thinking_sphinx/deltas/resque_delta'

		CONFIG_FILE = ENV['CONFIG_FILE']

		if CONFIG_FILE.nil? && ENV['RAILS_ROOT'].nil? && ENV['RAILS_ENV'].nil?
			raise "Either CONFIG_FILE or RAILS_ROOT and RAILS_ENV must be set!"
		end

		CONFIG_FILE ||= File.join(ENV['RAILS_ROOT'], 'config', "#{ENV['RAILS_ENV']}.sphinx.conf")

		indexes_ary = `egrep "^index\ [a-zA-Z_]+_(core|delta)" #{CONFIG_FILE} | cut -c 7- | sed -e "s/ :.*//"`

		indexes = SortedSet.new
		indexes_ary.each do |index|
			name, sep, type = index.rpartition('_')

			indexes << name
		end

		indexes.each do |name|
			Resque.redis.set("ts-delta:index:#{name}_delta:locked", 'true')
			system "indexer --config #{CONFIG_FILE} --rotate #{name}_core"
			ret = $?
				Resque.redis.del("ts-delta:index:#{name}_delta:locked")
			exit(-1) if ret.to_i != 0
			Resque.enqueue(
				ThinkingSphinx::Deltas::ResqueDelta::DeltaJob,
				["#{name}_delta"]
			)
		end
	end
end

namespace :ts do
  desc "Process stored delta index requests"
  task :rd => "thinking_sphinx:resque_delta"

	desc "Deals with large indexes one at a time with delta locking"
	task :si => "thinking_sphinx:smart_index"
end
