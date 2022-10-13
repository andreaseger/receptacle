# frozen_string_literal: true

module TestRepositories
  module Strategy
    class One
      def find(number, unscoped: true)
        puts "number: #{number} unscoped: #{unscoped.inspect}"
        number
      end
    end
  end

  module Wrapper
    class Add5ToNumber
      def find(number, unscoped:)
        yield(number + 5, unscoped: unscoped)
      end
    end

    class Add10ToNumberAndChangeUnscopedAndMultiplyResultBy1000
      def find(number, unscoped:)
        yield(number + 10, unscoped: !unscoped) * 100
      end
    end
  end

  module Test
    include Receptacle::Repo
    mediate :find
    wrappers [Wrapper::Add5ToNumber, Wrapper::Add10ToNumberAndChangeUnscopedAndMultiplyResultBy1000]
    strategy Strategy::One
  end
end
