# Receptacle

[![Gem Version](https://badge.fury.io/rb/receptacle.svg)](https://badge.fury.io/rb/receptacle)
[![Gem Downloads](https://img.shields.io/gem/dt/receptacle.svg)](https://rubygems.org/gems/receptacle)


## About

Provides easy and fast means to use the repository pattern to create separation
between your business logic and your data sources.

The ownership of this project has been taken over from https://github.com/andreaseger/receptacle, where you can still find version 1.0

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'receptacle'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install receptacle

## Usage

A repository mediates requests based on it's configuration to a strategy which
then itself implements the necessary functions to access the data source.

```
                                                +--------------------+      +--------+
                                                |                    |      |Database|
                                                |  DatabaseStrategy  +------>        |
                                                |                    |      |        |
+--------------------+     +--------------+     +----------^---------+      |        |
|                    |     |              |                |                +--------+
|   Business Logic   +----->  Repository  +----------------+
|                    |     |              |
+--------------------+     +--------|-----+     +--------------------+
                                    |           |                    |
                                    |           |  InMemoryStrategy  |
                            +-------|-----+     |                    |
                            |Configuration|     +--------------------+
                            +-------------+
```

Let's look at the pieces:

1. the repository itself - which is a simple module including the
   `Receptacle` mixin

```ruby
module Repository
  module User
    include Receptacle::Repo
    
    mediate :find
  end
end
```

2. at least one strategy class which are implemented as plain ruby classes

```ruby
module Strategy
  class Database
    def find(id:)
      # get data from data source and return a business entity
    end
  end
end
```

Optionally wrapper classes can be defined

```ruby
module Wrapper
  class Validator
    def before_find(id:)
      raise ArgumentError if id.nil?
      {id: id}
    end
  end
  class ModelMapper
    def after_find(return_value, **_kwargs)
      Model::User.new(return_value)
    end
  end
end
```

### Example

Everything combined a simple example could look like the following:

```ruby
require "receptacle"

module Repository
  module User
    include Receptacle::Repo
    mediate :find

    module Strategy
      class DB
        def find(id:)
          # code to find from the database
        end
      end
      class InMemory
        def find(id:)
          # code to find from InMemory store
        end
      end
    end

    module Wrapper
      class Validator
        def before_find(id:)
          raise ArgumentError if id.nil?
          {id: id}
        end
      end
      class ModelMapper
        def after_find(return_value, **_kwargs)
          Model::User.new(return_value)
        end
      end
    end
  end
end
```

For better separation to other repositories the fact that the repository itself
is a module can be used to nest both strategies and wrapper underneath.

Somewhere in your application config you now need to setup the strategy and the
wrappers for this repository like this:

```ruby
Repository::User.strategy Repository::User::Strategy::DB
Repository::User.wrappers [Repository::User::Wrapper::Validator,
                           Repository::User::Wrapper::ModelMapper])
```

With this setup to use the repository method is as simple and straight forward
as calling `Repository::User.find(id: 123)`

## Repository Pattern

What is the matter with this repository pattern and why should I care using it?

### Motivation

Often the business logic of applications directly accesses a data source like a
database. This has several disadvantages such as

- code duplication cased by repeated need to transform raw data into business
  entities
- no separation between business logic and access to the data source
- harder to add or change global policies like caching
- caused by missing isolation it's harder to test the business logic independent
  from the data source

### Solution

To improve on the disadvantages above and more we can introduce a repository
which mediates between the business logic and the data source. The data source
can be for example a database, an API(be it internal or external) or other web
services.

A repository provides the business logic with a stable interface to interact
with the data source. Hereby is the repository mapping the data to business
entities. Because the repository is a central place to access the data source
caching policies or similar can be applied easily there.

During testing the repository can be switched to a different strategy for
example a fast and lightweight in memory data store to ease the process of
testing the business logic.

Due to the ability to switch strategies a repository can also help to keep the
application architecture flexible as a change in strategy has no impact on the
business logic above.

## Details

### Strategy

A strategy is implemented as simple ruby class which implements the direct
access to a data source by implementing the same method (as instance method)
which was setup in the repository.

On each call to the repository a new instance of this class is created on which
then the mediated method is called.

```ruby
module Strategy
  class Database
    def find(id:)
      # get data from data source and return a business entity
    end
  end
end
```

Due to the nature of creating a new instance on each method call persistent
connections to the data source like a connection pool should be maintained
outside the strategy itself. For example in a singleton class.

### Wrapper

In addition to create a separation between data access and business logic often
there is the need to perform certain actions in the context of a data source
access. For example there can be the need to send message on a message bus whenever a
resource was created - independent of the strategy.

This gem allow one to add such actions without adding them to all strategies or
applying them in the business logic by using wrappers.

One or multiple wrappers sit logically between the repository and the
strategies. Based on the repository configuration it knows when and in which
order they should be applied. Right now there is support for 2 1/2 types of
actions.

1. a _before_ method action: This action is called before the final strategy
   method is executed. It has access to the method parameter and can even modify
   them.
2. a _after_ method action: This action is called after the strategy method was
   executed and has access to the method parameters passed to the strategy
   method and the return value. The return value could be modified here too.

The extra 1/2 action type is born by the fact that if a single wrapper class
implements both an before and after action for the same method the same wrapper
instance is used to execute both. Although this doesn't cover the all use cases
an _around_ method action would but many which need state before and after the
data source is accessed are covered.

#### Implementation

Wrapper actions are implemented as plain ruby classes which provide instance
methods named like `before_<method_name>` or `after_<method_name>` where
`<method_name>` is the repository/strategy method this action should be applied
to.

```ruby
module Wrapper
  class Validator
    def before_find(id:)
      raise ArgumentError if id.nil?
      {id: id}
    end
  end
end
```

This wrapper class would provide a before action for the `find` method. The
return value of this wrapper will be used as parameters for the strategy method
(or the next wrapper in line). Keyword arguments can simply be returned as hash.

If multiple wrapper classes are defined the before wrapper actions are executed
in the order the wrapper classes are defined while the after actions are applied
in reverse order.

### Memory Strategy

Although currently not part of the gem a simple memory strategy can be
implemented in this way:

```ruby
class MemoryStore
  class << self
    def store
      @store || clear
    end
    def clear
      @store = {}
    end
  end
  
  def clear
    self.class.clear
  end
  
  private def store
    self.class.store
  end
end
```

## How does it compare to other repository pattern implementations

Compared to other gem implementing the repository pattern this gem makes no
assumptions regarding the interface of your repository or what kind of data
source is used.
Some alternative have some interesting features nevertheless:

- [Hanami::Repository](https://github.com/hanami/model#repositories) is for one
  closely tied to the the Hanami entities and does not separate the repository
  interface from the implementing strategies. For straight forward mapping of
  entity to data source this might be enough though. Another caveat is that it
  currently only supports SQL data sources.
- [ROM::Repository](http://rom-rb.org/learn/repositories/) similarly is tied to
  other facilities of ROM like the ROM containers. It also appears to take a
  similar approach as Hanami to custom queries which should not leak to the
  outside application. There is predefined interface for manipulating resources
  through. The addition of `ROM::Changeset` brings an interesting addition to
  the mix which might make it an interesting alternative if using `ROM` fits
  into the applications structure.
  
This gem on the other hand makes absolutely no assumptions about your data
source or general structure of your code. It can be simply plugged in between
your business logic and data source to abstract the two. Of course like the other
repository pattern implementations strategy details should be hidden from the
interface. The data source can essentially be anything. A SQL database, a no-SQL
database, a JSON API or even a gem. Placing a gem behind a repository can be
useful if you're not yet sure this is the correct or best possible gem,
the [faraday](https://github.com/lostisland/faraday) gem is essentially doing
this by giving all the different http libraries a common interface).

## Testing

A module called `TestSupport` can be found
[here](https://github.com/andreaseger/receptacle/blob/master/lib/receptacle/test_support.rb).
Right now it provides 2 helper methods `with_strategy` to easily toggle
temporarily to another strategy and `ensure_method_delegators` to solve issues
caused by Rspec when attempting to stub a repository method. Both methods and
how to use them is described in more detail in the inline documentation. 

## Goals of this implementation

- small core codebase
- minimal processing overhead - fast method dispatching
- flexible - all kind of methods should possible to be mediated
- basic but powerful callbacks/hooks/observer possibilities

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake test` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file
to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/runtastic/receptacle. This project is intended to be a safe,
welcoming space for collaboration, and contributors are expected to adhere to
the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of
the [MIT License](http://opensource.org/licenses/MIT).

[runtastic]: https://github.com/runtastic
