# Receptacle

Provides easy and fast means to use the repository pattern to create separation
between your business logic and your data source.



## Repository Pattern

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

### Flow

The repository mediates requests based on it's configuration to a strategy which
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


## main goals of this implementation

- small core codebase
- minimal processing overhead (method dispatching should be as fast as possible)

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

As described above the Flow consists of at least two pieces:

1. the repository itself - which can simple be a module

```ruby
module Repository
  module User
    include Receptacle::Base
    
    mediate :find
  end
end
```

2. at least one strategy class

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
    include Receptacle
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

For better separation the fact that the repository itself is a module is used to
nest both strategies and wrapper underneath.

Somewhere in your application config you now need to setup the strategy and the
wrappers for this repository like this:

```ruby
Repository::User.strategy Repository::User::Strategy::DB
Repository::User.wrappers [Repository::User::Wrapper::Validator,
                           Repository::User::Wrapper::ModelMapper])
```

With this setup to use the repository method is as simple and straight forward
as calling `Repository::User.find(id: 123)`

## ToDo

- add support classes for testing
  - easy strategy switching
  - in memory strategy base class

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
https://github.com/andreaseger/receptacle. This project is intended to be a safe,
welcoming space for collaboration, and contributors are expected to adhere to
the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of
the [MIT License](http://opensource.org/licenses/MIT).

