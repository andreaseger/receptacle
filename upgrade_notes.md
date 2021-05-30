# Upgrade notes

## Upgrade from 1.0.0 to 2.0.0
If you do not use wrappers, there is nothing you need to do to upgrade.

The wrapper interface changed. With version 1.0 you had to implement methods prefixed with `before_` and `after_`. The return value of before-hooks where used as arguments to the next wrapper, while the return value of after-hooks was passed down to the previous wrapper. E.g:

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

In version 2.0 there are no before- and after-methods anymore. Instead you provide one method that wraps around the next wrapper or the strategy. You need to name the wrapper methods exactly as they are named in your strategy and you call `yield` to call the next wrapper. E.g:

```ruby
module Wrapper
  class Validator
    def find(id:)
      raise ArgumentError if id.nil?
      yield(id: id)
    end
  end
  
  class ModelMapper
    def find(id:)
      return_value = yield(id: id)
      Model::User.new(return_value)
    end
  end
end
```