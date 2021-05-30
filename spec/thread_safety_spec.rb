# frozen_string_literal: true

require "spec_helper"

describe Receptacle::Repo do
  let(:repository) do
    Class.new do
      include Receptacle::Repo

      mediate :foo

      wrapper_class = Class.new do
        def foo(number)
          @number = number
          @number += 1
          yield(@number)
        end
      end

      strategy_class = Class.new do
        def foo(number)
          @number = number
          @number *= 10
        end
      end

      wrappers([wrapper_class])
      strategy(strategy_class)
    end
  end

  it "is threasafe" do
    latch = CountDownLatch.new(1)

    t1 = Thread.new do
      latch.wait
      expect(repository.foo(5)).to eql(60)
    end
    t2 = Thread.new do
      latch.wait
      expect(repository.foo(6)).to eql(70)
    end
    t3 = Thread.new do
      latch.wait
      expect(repository.foo(9)).to eql(100)
    end

    latch.count_down
    t1.join
    t2.join
    t3.join
  end
end
