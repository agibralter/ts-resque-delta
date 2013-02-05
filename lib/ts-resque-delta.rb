require 'thinking_sphinx/deltas/resque_delta'
require 'flying_sphinx/resque_delta' if defined?(FlyingSphinx)
require 'thinking_sphinx/deltas/resque_delta/railtie' if defined?(Rails::Railtie)
