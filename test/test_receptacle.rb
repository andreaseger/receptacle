# frozen_string_literal: true

require "test_helper"
require "count_down_latch"
require "fixture"

class ReceptacleTest < Minitest::Test
  def callstack
    Thread.current[:receptacle_test_callstack]
  end

  def receptacle
    Fixtures::Test
  end

  def clear_callstack
    Thread.current[:receptacle_test_callstack] = []
  end

  def setup
    Receptacle::Registration.repositories[receptacle].strategy = nil
    Receptacle::Registration.repositories[receptacle].wrappers = []
    Receptacle::Registration.clear_method_cache(receptacle)
    clear_callstack
  end

  def test_provide_dsl
    mod = Module.new
    mod.include(Receptacle::Repo)
    assert mod.respond_to?(:strategy)
    assert mod.respond_to?(:mediate)
    assert mod.respond_to?(:wrappers)
  end

  def test_define_methods_via_mediate
    mod = Module.new
    mod.include(Receptacle::Repo)
    refute mod.respond_to?(:some_method)
    mod.mediate(:some_method)
    assert mod.respond_to?(:some_method)
  end

  def test_define_methods_via_delegate_to_strategy
    mod = Module.new
    mod.include(Receptacle::Repo)
    refute mod.respond_to?(:some_method)
    mod.delegate_to_strategy(:some_method)
    assert mod.respond_to?(:some_method)
  end

  def test_reserved_method_names
    mod = Module.new
    mod.include(Receptacle::Repo)

    # error for reserved method names
    %i[wrappers strategy mediate delegate_to_strategy].each do |method_name|
      assert_raises(Receptacle::Errors::ReservedMethodName) { mod.mediate(method_name) }
    end
  end

  def test_store_strategy_setup
    strategy = Fixtures::Strategy::One
    receptacle.strategy strategy
    assert_equal strategy, Receptacle::Registration.repositories[receptacle].strategy
    assert_equal strategy, receptacle.strategy

    strategy = Fixtures::Strategy::Two
    receptacle.strategy strategy
    assert_equal strategy, Receptacle::Registration.repositories[receptacle].strategy
  end

  def test_store_wrappers_setup
    assert_equal [], receptacle.wrappers
    assert_equal [], Receptacle::Registration.repositories[receptacle].wrappers

    wrapper = Minitest::Mock.new
    receptacle.wrappers wrapper
    assert_equal [wrapper], Receptacle::Registration.repositories[receptacle].wrappers
    assert_equal [wrapper], receptacle.wrappers

    receptacle.wrappers [wrapper]
    assert_equal [wrapper], Receptacle::Registration.repositories[receptacle].wrappers
    assert_equal [wrapper], receptacle.wrappers

    receptacle.wrappers []
    assert_equal [], receptacle.wrappers
    assert_equal [], Receptacle::Registration.repositories[receptacle].wrappers
  end

  def test_missing_strategy_setup
    assert_raises(Receptacle::Errors::NotConfigured) do
      receptacle.a(23)
    end
  end

  def test_method_mediation
    receptacle.strategy Fixtures::Strategy::One
    assert_equal 34, receptacle.a(34)
    assert_raises(NoMethodError) { receptacle.foo }
  end

  def test_argument_passing_no_wrapper
    receptacle.strategy Fixtures::Strategy::One
    receptacle.a(123)
    assert_equal [[Fixtures::Strategy::One, :a, 123]], callstack

    clear_callstack
    receptacle.wrappers [Fixtures::Wrapper::BeforeAandC]
    assert_equal 244, receptacle.a(234)
    assert_equal [
      [Fixtures::Wrapper::BeforeAandC, :before_a, 234],
      [Fixtures::Strategy::One, :a, 244]
    ], callstack
  end

  def test_argument_passing_array
    receptacle.strategy Fixtures::Strategy::One
    assert_equal 17, receptacle.b([5, 12])
    assert_equal [[Fixtures::Strategy::One, :b, [5, 12]]], callstack

    clear_callstack
    receptacle.wrappers [Fixtures::Wrapper::BeforeAll]
    assert_equal 50, receptacle.b([3, 14])
    assert_equal [
      [Fixtures::Wrapper::BeforeAll, :before_b, [3, 14]],
      [Fixtures::Strategy::One, :b, [3, 14, 33]]
    ], callstack
  end

  def test_argument_passing_kwargs
    receptacle.strategy Fixtures::Strategy::One
    assert_equal "ARGUMENT_PASSING", receptacle.c(10, string: "argument_passing")
    assert_equal [
      [Fixtures::Strategy::One, :c, "argument_passing"]
    ], callstack
    clear_callstack

    receptacle.wrappers [Fixtures::Wrapper::BeforeAandC]
    assert_equal "TEST_FOO", receptacle.c(10, string: "test")
    assert_equal [
      [Fixtures::Wrapper::BeforeAandC, :before_c, "test"],
      [Fixtures::Strategy::One, :c, "test_foo"]
    ], callstack
  end

  def test_argument_passing_block
    receptacle.strategy Fixtures::Strategy::One
    assert_equal "test_in_block", receptacle.d(context: "test") { |c| "#{c}_in_block" }
    assert_equal [
      [Fixtures::Strategy::One, :d, "test"]
    ], callstack
    clear_callstack

    receptacle.wrappers [Fixtures::Wrapper::BeforeAll]
    assert_equal "test_bar_in_block", receptacle.d(context: "test") { |c| "#{c}_in_block" }
    assert_equal [
      [Fixtures::Wrapper::BeforeAll, :before_d, "test"],
      [Fixtures::Strategy::One, :d, "test_bar"]
    ], callstack
  end

  def test_argument_passing_multiple_arguments
    receptacle.strategy Fixtures::Strategy::One
    assert_equal 46, receptacle.e(1, 45)
    assert_equal [
      [Fixtures::Strategy::One, :e, [1, 45]]
    ], callstack
    clear_callstack

    receptacle.wrappers [Fixtures::Wrapper::BeforeAll, Fixtures::Wrapper::AfterAll]
    assert_equal 348, receptacle.e(5, 33)
    assert_equal [
      [Fixtures::Wrapper::BeforeAll, :before_e, [5, 33]],
      [Fixtures::Strategy::One, :e, [10, 38]],
      [Fixtures::Wrapper::AfterAll, :after_e, [10, 38], 48]
    ], callstack
  end

  def test_after_wrapper
    receptacle.strategy Fixtures::Strategy::Two
    receptacle.wrappers [Fixtures::Wrapper::AfterAll]
    assert_equal 110, receptacle.a(5)
    assert_equal [
      [Fixtures::Strategy::Two, :a, 5],
      [Fixtures::Wrapper::AfterAll, :after_a, 5, 10]
    ], callstack
    clear_callstack

    assert_equal 112, receptacle.b([5, 7])
    assert_equal [
      [Fixtures::Strategy::Two, :b, [5, 7]],
      [Fixtures::Wrapper::AfterAll, :after_b, [5, 7], 12]
    ], callstack
    clear_callstack

    assert_equal "WRAPPER_foobar", receptacle.c(10, string: "wrapper")
    assert_equal "after_f + f_body", receptacle.f { "f_body"}
    assert_equal [
      [Fixtures::Strategy::Two, :c, "wrapper"],
      [Fixtures::Wrapper::AfterAll, :after_c, "wrapper", "WRAPPER"],
      [Fixtures::Strategy::Two, :f],
      [Fixtures::Wrapper::AfterAll, :after_f, "f_body"]
    ], callstack
    clear_callstack

    assert_equal "test_in_block_foobar", receptacle.d(context: "test") { |c| "#{c}_in_block" }
    assert_equal [
      [Fixtures::Strategy::Two, :d, "test"],
      [Fixtures::Wrapper::AfterAll, :after_d, "test", "test_in_block"]
    ], callstack
  end

  def test_before_and_after_wrapper
    receptacle.strategy Fixtures::Strategy::Two
    receptacle.wrappers [Fixtures::Wrapper::BeforeAfterA]
    assert_equal 123, receptacle.a(54)
    assert_equal [
      [Fixtures::Wrapper::BeforeAfterA, :before_a, 54],
      [Fixtures::Strategy::Two, :a, 59],
      [Fixtures::Wrapper::BeforeAfterA, :after_a, 59, 118]
    ], callstack
  end

  def test_multiple_wrapper
    receptacle.strategy Fixtures::Strategy::Two
    receptacle.wrappers [Fixtures::Wrapper::BeforeAfterA, Fixtures::Wrapper::BeforeAfterAandB]
    assert_equal 53, receptacle.a(4)
    assert_equal [
      [Fixtures::Wrapper::BeforeAfterA, :before_a, 4],
      [Fixtures::Wrapper::BeforeAfterAandB, :before_a, 9],
      [Fixtures::Strategy::Two, :a, 19],
      [Fixtures::Wrapper::BeforeAfterAandB, :after_a, 19, 38],
      [Fixtures::Wrapper::BeforeAfterA, :after_a, 19, 48]
    ], callstack
    clear_callstack

    assert_equal 92, receptacle.b([1, 6, 9])
    assert_equal [
      [Fixtures::Wrapper::BeforeAfterAandB, :before_b, [1, 6, 9]],
      [Fixtures::Strategy::Two, :b, [1, 6, 9, 66]],
      [Fixtures::Wrapper::BeforeAfterAandB, :after_b, [1, 6, 9, 66], 82]
    ], callstack
  end

  def test_call_order_after_setup_change
    receptacle.strategy Fixtures::Strategy::One
    receptacle.wrappers [Fixtures::Wrapper::BeforeAll, Fixtures::Wrapper::AfterAll]
    assert_equal "BLA_BAR_foobar", receptacle.c(10, string: "bla")
    assert_equal [
      [Fixtures::Wrapper::BeforeAll, :before_c, "bla"],
      [Fixtures::Strategy::One, :c, "bla_bar"],
      [Fixtures::Wrapper::AfterAll, :after_c, "bla_bar", "BLA_BAR"]
    ], callstack
    clear_callstack

    receptacle.strategy Fixtures::Strategy::Two
    receptacle.wrappers [Fixtures::Wrapper::BeforeAll, Fixtures::Wrapper::BeforeAandC]
    assert_equal "BLA_BAR_FOO", receptacle.c(10, string: "bla")
    assert_equal [
      [Fixtures::Wrapper::BeforeAll, :before_c, "bla"],
      [Fixtures::Wrapper::BeforeAandC, :before_c, "bla_bar"],
      [Fixtures::Strategy::Two, :c, "bla_bar_foo"]
    ], callstack
  end

  def test_sharing_state_between_before_after_inside_wrapper
    receptacle.strategy Fixtures::Strategy::One
    receptacle.wrappers Fixtures::Wrapper::BeforeAfterWithStateC

    assert_equal "WOHOO_WAT5", receptacle.c(10, string: "wohoo")
    assert_equal [
      [Fixtures::Wrapper::BeforeAfterWithStateC, :before_c, "wohoo"],
      [Fixtures::Strategy::One, :c, "wohoo_wat"],
      [Fixtures::Wrapper::BeforeAfterWithStateC, :after_c, "wohoo_wat", "WOHOO_WAT"]
    ], callstack

    assert_equal "NEW_STATE_WAT9", receptacle.c(10, string: "new_state")
  end

  def test_after_wrapper_order
    receptacle.strategy Fixtures::Strategy::One
    receptacle.wrappers [Fixtures::Wrapper::AfterAll, Fixtures::Wrapper::BeforeAfterA]

    assert_equal 187, receptacle.a(77)
    assert_equal [
      [Fixtures::Wrapper::BeforeAfterA, :before_a, 77],
      [Fixtures::Strategy::One, :a, 82],
      [Fixtures::Wrapper::BeforeAfterA, :after_a, 82, 82],
      [Fixtures::Wrapper::AfterAll, :after_a, 82, 87]
    ], callstack
  end

  def test_thread_safety_for_mediated_method_calls
    # This config is global for the whole application
    receptacle.strategy Fixtures::Strategy::One
    receptacle.wrappers Fixtures::Wrapper::BeforeAfterWithStateC

    latch = CountDownLatch.new(1)

    t1 = Thread.new do
      latch.wait
      assert_equal "T1_WAT2", receptacle.c(10, string: "t1")
    end
    t2 = Thread.new do
      latch.wait
      assert_equal "T2_WAT2", receptacle.c(10, string: "t2")
    end
    t3 = Thread.new do
      latch.wait
      assert_equal "T3_WAT2", receptacle.c(10, string: "t3")
    end

    latch.count_down
    t1.join
    t2.join
    t3.join
  end
end
