source "http://rubygems.org"

# Specify your gem's dependencies in ts-resque-delta.gemspec
gemspec

group :development do
  if RUBY_PLATFORM =~ /darwin/i
    gem 'rb-fsevent'
    gem 'ruby_gntp'
  else
    gem 'rb-fsevent', :require => false
    gem 'growl', :require => false
  end
  if RUBY_PLATFORM =~ /linux/i
    gem 'rb-inotify'
    gem 'libnotify'
  else
    gem 'rb-inotify', :require => false
    gem 'libnotify', :require => false
  end
end

# Provided as an example for developers to use
# group :test do
#   if RUBY_VERSION >= '1.9'
#     gem 'debugger'
#   else
#     gem 'ruby-debug'
#   end
# end
