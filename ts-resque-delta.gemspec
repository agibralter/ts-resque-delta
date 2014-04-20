# -*- encoding: utf-8 -*-
Gem::Specification.new do |s|
  s.name        = 'ts-resque-delta'
  s.version     = '1.2.4'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Aaron Gibralter', 'Pat Allan']
  s.email       = ['aaron.gibralter@gmail.com']
  s.homepage    = 'https://github.com/agibralter/ts-resque-delta'
  s.summary     = %q{Thinking Sphinx - Resque Deltas}
  s.description = %q{Manage delta indexes via Resque for Thinking Sphinx}

  s.rubyforge_project = 'ts-resque-delta'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_dependency 'thinking-sphinx',     '>= 1.5.0'
  s.add_dependency 'resque',              '~> 1.10'

  s.add_development_dependency 'activerecord',     '~> 3.2'
  s.add_development_dependency 'activesupport',    '~> 3.2'
  s.add_development_dependency 'appraisal',        '~> 0.4.1'
  s.add_development_dependency 'combustion',       '~> 0.4.0'
  s.add_development_dependency 'database_cleaner', '~> 0.7.1'
  s.add_development_dependency 'mock_redis',       '~> 0.12.1'
  s.add_development_dependency 'mysql2',           '~> 0.3.12b4'
  s.add_development_dependency 'pg',               '~> 0.11'
  s.add_development_dependency 'rake',             '>= 0.9.2'
  s.add_development_dependency 'rspec',            '~> 2.11.0'
end
