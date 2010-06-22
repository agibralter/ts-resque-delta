require 'rubygems'
require 'cucumber'
require 'spec/expectations'
require 'fileutils'
require 'active_record'

PROJECT_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))

$:.unshift(File.join(PROJECT_ROOT, 'lib'))
$:.unshift(File.dirname(__FILE__))

require 'cucumber/thinking_sphinx/internal_world'

Time.zone_default = Time.__send__(:get_zone, 'Melbourne')
ActiveRecord::Base.time_zone_aware_attributes = true
ActiveRecord::Base.default_timezone = :utc

world = Cucumber::ThinkingSphinx::InternalWorld.new
world.configure_database

require 'thinking_sphinx'
require 'thinking_sphinx/deltas/resque_delta'

world.setup

require 'redis_test_setup'
RedisTestSetup.start_redis!(PROJECT_ROOT, :cucumber)
Before do
  Resque.redis.flushall
end
