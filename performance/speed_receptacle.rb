# frozen_string_literal: true
require 'receptacle'
module Speed
  include Receptacle
  mediate :a
  mediate :b
  mediate :c
  mediate :d
  mediate :e
  mediate :f
  mediate :g
  module Strategy
    class One
      def a(arg)
        arg
      end
      alias b a
      alias c a
      alias d a
      alias e a
      alias f a
      alias g a
    end
  end

  module Wrappers
    class W1
      def before_a(args)
        args
      end

      def after_a(return_values, _)
        return_values
      end

      def before_f(args)
        args
      end

      def after_f(return_values, _)
        return_values
      end
    end

    class W2
      # :a
      def before_a(args)
        args
      end

      def after_a(return_values, _)
        return_values
      end

      # :b
      def before_b(args)
        args
      end

      def after_b(return_values, _)
        return_values
      end
    end
    class W3
      def before_a(args)
        args
      end

      def before_c(args)
        args
      end
    end

    class W4
      def after_a(return_values, _)
        return_values
      end

      def after_d(return_value, _)
        return_value
      end
    end

    class W5
      def before_b(args)
        args
      end

      def after_c(return_value, _)
        return_value
      end
    end

    class W6
      def after_b(return_value, _)
        return_value
      end

      def before_e(args)
        args
      end
    end
  end
end
