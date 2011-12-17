require 'cucumber'
require 'rspec/expectations'
require 'fileutils'
require 'active_record'
require 'mock_redis'

PROJECT_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))

$:.unshift(File.join(PROJECT_ROOT, 'lib'))
$:.unshift(File.dirname(__FILE__))

require 'cucumber/thinking_sphinx/internal_world'

ActiveRecord::Base.default_timezone = :utc

world = Cucumber::ThinkingSphinx::InternalWorld.new
world.configure_database

require 'thinking_sphinx'
require 'thinking_sphinx/deltas/resque_delta'

world.setup

Resque.redis = MockRedis.new
Before do
  Resque.redis.flushall
end

require 'database_cleaner'
require 'database_cleaner/cucumber'
DatabaseCleaner.strategy = :truncation
