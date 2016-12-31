require 'receptacle'
module User
  include Receptacle::Base
  mediate :find
  mediate :where
  mediate :all
  module Strategy
    class Real
      def find(arg)
        arg
      end

      def where(args)
        args
      end

      def all(args)
        args
      end
    end
  end

  module Wrappers
    class First
      def before_where(args)
        args
      end

      def after_where(_args, return_values)
        return_values
      end
    end
    class Second
      def before_where(args)
        args
      end

      def after_where(_args, return_values)
        return_values
      end
      attr_accessor :state
    end
    class ArgumentPasser
      def before_where(args)
        args
      end

      def before_find(args)
        args
      end

      def before_with(context)
        { context: context }
      end

      def after_meh; end
    end
    class LogResults
      def before_find(args)
        args
      end

      def after_where(_, return_values)
        return_values
      end
    end
  end
end
