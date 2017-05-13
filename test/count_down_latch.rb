# frozen_string_literal: true

class CountDownLatch
  attr_reader :count

  def initialize(to)
    @count = to.to_i
    raise ArgumentError, 'cannot count down from negative integer' unless @count >= 0
    @lock = Mutex.new
    @condition = ConditionVariable.new
  end

  def count_down
    @lock.synchronize do
      @count -= 1 if @count > 0
      @condition.broadcast if @count.zero?
    end
  end

  def wait
    @lock.synchronize do
      @condition.wait(@lock) while @count > 0
    end
  end
end
