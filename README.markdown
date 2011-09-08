Delayed Deltas for Thinking Sphinx (with Resque)
================================================
**This code is HEAVILY borrowed from
[ts-delayed-delta](https://github.com/freelancing-god/ts-delayed-delta).**

Installation
------------
This gem depends on the following gems: _thinking-sphinx_, _resque_, and
_resque-lock-timeout_.

    gem install ts-resque-delta

Add _ts-resque-delta_ to your **Gemfile** file, with the rest of your gem
dependencies:

    gem 'ts-resque-delta', '1.1.1'

If you're using Rails 3, the rake tasks will automatically be loaded by Rails.
If you're using Rails 2, add the following line to your **Rakefile**:

    require 'thinking_sphinx/deltas/resque_delta/tasks'

Add the delta property to each `define_index` block:

    define_index do
      # ...
      set_property :delta => ThinkingSphinx::Deltas::ResqueDelta
    end

If you've never used delta indexes before, you'll want to add the boolean
column named `:delta` to each model's table (note, you must set the `:default`
value to `true`):

    def self.up
      add_column :foos, :delta, :boolean, :default => true, :null => false
    end

Also, I highly recommend adding a MySQL index to the table of any model using
delta indexes. The Sphinx indexer uses `WHERE table.delta = 1` whenever the
delta indexer runs and `... = 0` whenever the normal indexer runs. Having the
MySQL index on the delta column will generally be a win:

    def self.up
      # ...
      add_index :foos, :delta
    end

Usage
-----
Once you've got it all set up, all you need to do is make sure that the Resque
worker is running. You can do this by specifying the `:ts_delta` queue when
running Resque:

    QUEUE=ts_delta,other_queues rake resque:work

Additionally, ts-resque-delta will wrap thinking-sphinx's
`thinking_sphinx:index` and `thinking_sphinx:reindex` tasks with
`thinking_sphinx:lock_deltas` and `thinking_sphinx:unlock_deltas`. This will
prevent the delta indexer from running at the same time as the main indexer.

Finally, ts-resque-delta also provides a rake task called
`thinking_sphinx:smart_index` (or `ts:si` for short). This task, instead of
locking all the delta indexes at once while the main indexer runs, will lock
each delta index independently and sequentially. Thay way, your delta indexer
can run while the main indexer is processing large core indexes.

Contributors (for ts-delayed-delta)
-----------------------------------
* [Aaron Gibralter](https://github.com/agibralter)
* [Ryan Schlesinger](https://github.com/ryansch) (Locking/`smart_index`)

Original Contributors (for ts-delayed-delta)
--------------------------------------------
* [Pat Allan](https://github.com/freelancing-god)
* [Ryan Schlesinger](https://github.com/ryansch) (Allowing installs as a plugin)
* [Maximilian Schulz](https://max.jungeelite.de) (Ensuring compatibility with Bundler)
* [Edgars Beigarts](https://github.com/ebeigarts) (Adding intelligent description for tasks)
* [Alexander Simonov](https://simonov.me/) (Explicit table definition)

Copyright
---------
Copyright (c) 2011 Aaron Gibralter, and released under an MIT Licence.
