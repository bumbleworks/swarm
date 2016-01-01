# Swarm

[![Gem Version](https://badge.fury.io/rb/swarm.svg)](https://badge.fury.io/rb/swarm)

Swarm is a (very much still work-in-progress) workflow engine for Ruby, combining a process definition DSL, a set of built-in expressions, a worker framework to actually run process instances, and a storage mechanism to persist instances and deferred expressions.

Currently it requires Redis as a backend to persist state (though for testing you can use transient in-process memory storage).  The goal is to extract the storage so other backends can be swapped in as the process state repository.

For performing the work itself, Swarm only comes with an in-process memory storage, which means jobs queued up at the time of stopping the worker will be lost.  For a non-volatile worker, you'll want to use [swarm-beanstalk](http://github.com/bumbleworks/swarm-beanstalk), which uses [beanstalkd](http://kr.github.io/beanstalkd/) (via [beaneater](https://github.com/beanstalkd/beaneater)).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'swarm'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install swarm

## Usage

Instructions coming soon!

## Acknowledgements

Huge thanks to @jmettraux, author of (now discontinued) [ruote](https://github.com/jmettraux/ruote), for getting me excited about workflow engines, and for inspiring this fun and educational project of mine.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/swarm/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
