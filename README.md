# Receptacle

Provides easy and fast means to use the repository pattern for parts of your
codebase. E.g. database calls can be masked behind a repository and leave
implementation of the actuall access to a specific strategy. For external
dependencies a second strategy which gets switch in for local tests lets your
application be agnostic about where or how the data is garthered as the
interface and observed functionality stays the same between strategies.

## Goals of this implementation

- small core codebase
- minimal processing overhead(method dispatching should be as fast as possible)

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

```ruby
require "receptacle"

module Repository
  module User
    include Receptacle::Base
    mediate :find
    module Strategy
      class DB
        def find(id:)
          # code to find from the database
        end
      end
      class InMemory
        def find(id:)
          # code to find from inMemory store
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

Repository::User.strategy Repository::User::Strategy::DB
Repository::User.wrappers [Repository::User::Wrapper::Validator,
                           Repository::User::Wrapper::ModelMapper])

Repository::User.find(id: 123)
# this will basically do the following
# args = Repository::User::Wrapper::Validator.new.before_find(id: 123)
# return_value = Repository::User::Strategy::DB.new.find(args)
# return_value = Repository::User::Wrapper::ModelMapper.new.after_find(return_value, args)
```

If the same wrapper class implements both a `before_*` and `after_*` for the
same method the wrapper instance is shared between both calls, making it
possible to share state between both calls.

## ToDo

- improve readme on why and how to use it
- add examples (wrappers? switching strategies, use for testing)

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

