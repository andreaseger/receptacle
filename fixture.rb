# frozen_string_literal: true
require './receptacle'

module Fixtures
  class CallStack
    include Singleton
    def initialize
      self.stack = []
    end
    attr_accessor :stack
  end

  module User
    include Receptacle::Base
    delegate_to_strategy :where
    delegate_to_strategy :clear
    delegate_to_strategy :find
    delegate_to_strategy :with
    module Strategy
      class Base
        def clear
          :clear
        end
      end
      class Fake < Base
        def where(args)
          CallStack.instance.stack.push([self.class, __method__, args])
          :where
        end
      end
      class Real < Base
        def where(args)
          CallStack.instance.stack.push([self.class, __method__, args])
          :where
        end

        def find(**kwargs)
          CallStack.instance.stack.push([self.class, __method__, kwargs])
          :find
        end

        def with(context:)
          CallStack.instance.stack.push([self.class, __method__, context])
          yield(context)
        end
      end
    end
    module Wrappers
      class First
        def before_where(args)
          CallStack.instance.stack.push([self.class, __method__])
          args
        end

        def after_where(_args, return_values)
          CallStack.instance.stack.push([self.class, __method__])
          return_values
        end
      end
      class Second
        def before_where(args)
          CallStack.instance.stack.push([self.class, __method__])
          args
        end

        def after_where(_args, return_values)
          CallStack.instance.stack.push([self.class, __method__])
          return_values
        end
        attr_accessor :state
      end
      class ArgumentPasser
        def before_where(args)
          CallStack.instance.stack.push([self.class, __method__])
          args
        end

        def before_find(**kwargs)
          CallStack.instance.stack.push([self.class, __method__])
          kwargs
        end

        def before_with(context)
          CallStack.instance.stack.push([self.class, __method__])
          { context: context }
        end

        def after_meh; end
      end
      class LogResults
        def before_find(args)
          args
        end

        def after_where(_, return_values)
          CallStack.instance.stack.push([self.class, __method__, return_values])
          return_values
        end
      end
    end
  end
end
