# frozen_string_literal: true

require "receptacle"

module Fixtures
  def self.callstack
    Thread.current[:receptacle_test_callstack] ||= []
  end

  module Test
    include Receptacle::Repo
    mediate :a
    mediate :b
    mediate :c
    mediate :d
    mediate :e
    mediate :f
  end

  module Strategy
    class One
      def a(number)
        Fixtures.callstack.push([self.class, __method__, number])
        number
      end

      def b(array)
        Fixtures.callstack.push([self.class, __method__, array])
        array.reduce(:+)
      end

      def c(a, string:)
        Fixtures.callstack.push([self.class, __method__, string])
        string.upcase
      end

      def d(context:)
        Fixtures.callstack.push([self.class, __method__, context])
        yield(context)
      end

      def e(first, second)
        Fixtures.callstack.push([self.class, __method__, [first, second]])
        first + second
      end

      def f
        Fixtures.callstack.push([self.class, __method__])
        yield
      end
    end

    class Two < One
      def a(number)
        Fixtures.callstack.push([self.class, __method__, number])
        number * 2
      end
    end
  end

  module Wrapper
    class BeforeAfterA
      def before_a(number)
        Fixtures.callstack.push([self.class, __method__, number])
        number + 5
      end

      def after_a(return_value, number)
        Fixtures.callstack.push([self.class, __method__, number, return_value])
        return_value + 5
      end
    end

    class BeforeAfterAandB
      # :a
      def before_a(number)
        Fixtures.callstack.push([self.class, __method__, number])
        number + 10
      end

      def after_a(return_value, number)
        Fixtures.callstack.push([self.class, __method__, number, return_value])
        return_value + 10
      end

      # :b
      def before_b(array)
        Fixtures.callstack.push([self.class, __method__, array])
        array | [66]
      end

      def after_b(return_value, array)
        Fixtures.callstack.push([self.class, __method__, array, return_value])
        return_value + 10
      end
    end

    class BeforeAfterWithStateC
      # :c
      def before_c(a, string:)
        Fixtures.callstack.push([self.class, __method__, string])
        @state = string.length
        [a, {string: string + "_wat"}]
      end

      # :c
      def after_c(return_value, a, string:)
        Fixtures.callstack.push([self.class, __method__, string, return_value])
        return_value + @state.to_s
      end
    end

    class BeforeAandC
      # :a
      def before_a(number)
        Fixtures.callstack.push([self.class, __method__, number])
        number + 10
      end

      # :c
      def before_c(a, string:)
        Fixtures.callstack.push([self.class, __method__, string])
        [a, {string: string + "_foo"}]
      end
    end

    class BeforeAll
      # :a
      def before_a(number)
        Fixtures.callstack.push([self.class, __method__, number])
        number + 50
      end

      # :a
      def before_b(array)
        Fixtures.callstack.push([self.class, __method__, array])
        array | [33]
      end

      # :c
      def before_c(a, string:)
        Fixtures.callstack.push([self.class, __method__, string])
        [a + 10, {string: string + "_bar"}]
      end

      # :d
      def before_d(context:)
        Fixtures.callstack.push([self.class, __method__, context])
        {context: context + "_bar"}
      end

      def before_e(first, second)
        Fixtures.callstack.push([self.class, __method__, [first, second]])
        [first + 5, second + 5]
      end

      def before_f
        Fixtures.callstack.push([self.class, __method__])
        "before_f"
      end
    end

    class AfterAll
      # :a
      def after_a(return_value, number)
        Fixtures.callstack.push([self.class, __method__, number, return_value])
        return_value + 100
      end

      # :b
      def after_b(return_value, array)
        Fixtures.callstack.push([self.class, __method__, array, return_value])
        return_value + 100
      end

      # :c
      def after_c(return_value, a, string:)
        Fixtures.callstack.push([self.class, __method__, string, return_value])
        return_value + "_foobar"
      end

      # :d
      def after_d(return_value, context:)
        Fixtures.callstack.push([self.class, __method__, context, return_value])
        return_value + "_foobar"
      end

      def after_e(return_value, first, second)
        Fixtures.callstack.push([self.class, __method__, [first, second], return_value])
        return_value + 300
      end

      def after_f(return_value)
        Fixtures.callstack.push([self.class, __method__, return_value])
        "after_f + #{return_value}"
      end
    end
  end
end
