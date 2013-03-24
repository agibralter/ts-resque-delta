require 'thinking_sphinx'
require 'thinking_sphinx/deltas/resque_delta'
#require 'flying_sphinx'
#require 'flying_sphinx/resque_delta'

require 'mock_redis'
require 'fakefs/spec_helpers'

RSpec.configure do |c|
  c.filter_run :focus => true
  c.run_all_when_everything_filtered = true
  c.treat_symbols_as_metadata_keys_with_true_values = true
end

SPEC_BIN_PATH = File.expand_path(File.join(File.dirname(__FILE__), 'bin'))
