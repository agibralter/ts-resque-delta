require 'rubygems'
require 'bundler'

Bundler.require :default, :development

require 'thinking_sphinx/railtie'

Combustion.initialize! :active_record

root = File.expand_path File.dirname(__FILE__)
Dir["#{root}/support/**/*.rb"].each { |file| require file }

RSpec.configure do |config|
  # enable filtering for examples
  config.filter_run :wip => nil
  config.run_all_when_everything_filtered = true
end

SPEC_BIN_PATH = File.expand_path(File.join(File.dirname(__FILE__), 'bin'))
