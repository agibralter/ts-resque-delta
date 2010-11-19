require "jeweler"
require "yard"

YARD::Rake::YardocTask.new

Jeweler::Tasks.new do |gem|
  gem.name        = "ts-resque-delta"
  gem.summary     = "Thinking Sphinx - Resque Deltas"
  gem.description = "Manage delta indexes via Resque for Thinking Sphinx"
  gem.email       = "aaron.gibralter@gmail.com"
  gem.homepage    = "http://github.com/agibralter/ts-resque-delta"
  gem.authors     = ["Aaron Gibralter"]
  gem.add_dependency("thinking-sphinx", "~> 1.4.0")
  gem.add_dependency("resque", "~> 1.10.0")
  gem.add_dependency("resque-lock-timeout", "~> 0.2.1")
  gem.add_development_dependency("rspec", ">= 1.2.9")
  gem.add_development_dependency("yard", ">= 0")
  gem.add_development_dependency("cucumber", ">= 0")
  gem.add_development_dependency("database_cleaner", ">= 0.5.2")
  gem.files = FileList[
    "lib/**/*.rb",
    "LICENSE",
    "README.markdown"
  ]
  gem.test_files = FileList[
    ["Rakefile"] + %w(config features spec tasks).collect { |d| "#{d}/**/*" }
  ]
end

Jeweler::GemcutterTasks.new
