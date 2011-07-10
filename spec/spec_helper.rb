$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'spec'
require 'spec/autorun'

require 'thinking_sphinx'
require 'thinking_sphinx/deltas/resque_delta'
require 'flying_sphinx'
require 'flying_sphinx/resque_delta'
