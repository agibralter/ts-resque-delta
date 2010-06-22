$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'spec'
require 'spec/autorun'

require 'thinking_sphinx'
require 'thinking_sphinx/deltas/resque_delta'
