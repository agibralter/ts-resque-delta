Delayed Deltas for Thinking Sphinx (with Resque)
================================================
[![Build Status](https://secure.travis-ci.org/agibralter/ts-resque-delta.png?branch=master)](http://travis-ci.org/agibralter/ts-resque-delta)

**This code is HEAVILY borrowed from
[ts-delayed-delta](https://github.com/freelancing-god/ts-delayed-delta).**

Installation
------------

This gem depends on the following gems: `thinking-sphinx` and `resque`.

Currently, you'll need Thinking Sphinx v1.5.0 (for Rails 2), v2.1.0
(for Rails 3), or - ideally - v3.0.3 or newer (for Rails 3.1 onwards). If you're
on a version of Thinking Sphinx that's too old, you better go upgrade - but
otherwise, add `ts-resque-delta` to your `Gemfile` file with the rest of your
gem dependencies:

    gem 'ts-resque-delta', '~> 2.0.0'

Add the delta property to index definition. If you're using Thinking Sphinx v3,
then it'll look something like this:

    ThinkingSphinx::Index.define(:article,
      :with  => :active_record,
      :delta => ThinkingSphinx::Deltas::ResqueDelta
    ) do
      # fields and attributes and so on...
    end

But if you're still using v1.5 or v2.1, you'll want the following:

    define_index do
      # fields and attributes and so on...

      set_property :delta => ThinkingSphinx::Deltas::ResqueDelta
    end

If you've never used delta indexes before, you'll need to add the boolean
column named `:delta` to each table for indexed models. A database index for
that column is also recommended.

    def change
      add_column :articles, :delta, :boolean, :default => true, :null => false
      add_index  :articles, :delta
    end

Usage
-----

Once you've got it all set up, all you need to do is make sure that the Resque
worker is running. You can do this by specifying the `ts_delta` queue when
running Resque:

    QUEUE=ts_delta,other_queues rake resque:work

Contributors (for ts-resque-delta)
-----------------------------------

* [Aaron Gibralter](https://github.com/agibralter)
* [Ryan Schlesinger](https://github.com/ryansch) (Locking/`smart_index`)
* [Pat Allan](https://github.com/freelancing-god) (FlyingSphinx support)
* [James Richard](https://github.com/ketzusaka)

Original Contributors (for ts-delayed-delta)
--------------------------------------------

* [Pat Allan](https://github.com/freelancing-god)
* [Ryan Schlesinger](https://github.com/ryansch) (Allowing installs as a plugin)
* [Maximilian Schulz](https://max.jungeelite.de) (Ensuring compatibility with Bundler)
* [Edgars Beigarts](https://github.com/ebeigarts) (Adding intelligent description for tasks)
* [Alexander Simonov](https://simonov.me/) (Explicit table definition)

Copyright
---------

Copyright (c) 2011-2014 Aaron Gibralter and Pat Allan, and released under an MIT
Licence.
