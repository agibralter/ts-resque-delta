Delayed Deltas for Thinking Sphinx (with Resque)
================================================

**This code is HEAVILY borrowed from [ts-delayed-delta](http://github.com/freelancing-god/ts-delayed-delta).**

Installation
------------

You'll need Thinking Sphinx 1.3.0 or later, and Resque as well. The latter is flagged as a dependency.

    gem install ts-resque-delta

In your `Gemfile` file, with the rest of your gem dependencies:

    gem 'ts-resque-delta', '0.0.1', :require => 'thinking_sphinx/deltas/resque_delta'

And add the following line to the bottom of your `Rakefile`:

    require 'thinking_sphinx/deltas/resque_delta/tasks'

For the indexes you want to use this delta approach, make sure you set that up in their `define_index` blocks.

    define_index do
      # ...
      set_property :delta => ThinkingSphinx::Deltas::ResqueDelta
    end

If you've never used delta indexes before, you'll want to add the boolean column named delta to each model that is using the approach.

    def self.up
      add_column :articles, :delta, :boolean, :default => true, :null => false
    end

Usage
-----

Once you've got it all set up, all you need to do is make sure that the Resque worker is running. You can do this either by running Resque's workers and specifying the `:ts_delta` queue, or Thinking Sphinx's custom rake task:

    rake thinking_sphinx:resque_delta

There's also a short name for the same task, to save your fingers some effort:

    rake ts:rd

Original Contributors (for ts-delayed-delta)
--------------------------------------------

* [Pat Allan](http://github.com/freelancing-god)
* [Ryan Schlesinger](http://github.com/ryansch) (Allowing installs as a plugin)
* [Maximilian Schulz](http://max.jungeelite.de) (Ensuring compatibility with Bundler)
* [Edgars Beigarts](http://github.com/ebeigarts) (Adding intelligent description for tasks)
* [Alexander Simonov](http://simonov.me/) (Explicit table definition)

Copyright
---------

Copyright (c) 2010 Aaron Gibralter, and released under an MIT Licence.
