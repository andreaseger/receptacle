# frozen_string_literal: true
require 'test_helper'
require 'fixture'

describe Receptacle do
  parallelize_me!
  def callstack
    Fixtures::CallStack.instance.stack
  end

  def receptacle
    Fixtures::User
  end

  before do
    Receptacle::Registration.repos[receptacle].strategy = nil
    Receptacle::Registration.repos[receptacle].wrappers = []
    Receptacle::Registration.clear_method_cache(receptacle)
    Fixtures::CallStack.instance.stack = []
  end

  it 'keeps track of Receptacle - Strategy config' do
    strategy = Fixtures::User::Strategy::Fake
    receptacle.strategy strategy
    assert_equal strategy, Receptacle::Registration.repos[receptacle].strategy
  end

  it 'keeps track of config after change of strategy' do
    strategy = Fixtures::User::Strategy::Fake
    receptacle.strategy strategy

    strategy = Fixtures::User::Strategy::Real
    receptacle.strategy strategy
    assert_equal strategy, Receptacle::Registration.repos[receptacle].strategy
  end

  it 'keeps track of wrappers' do
    wrapper = Minitest::Mock.new
    receptacle.wrappers wrapper
    assert_equal [wrapper], Receptacle::Registration.repos[receptacle].wrappers
  end

  it 'responds to delegated methods' do
    assert receptacle.respond_to?(:where)
  end

  it 'raises error if no strategy registered' do
    assert_raises(Receptacle::Errors::NotConfigured) do
      receptacle.where('test')
    end
  end

  it 'has methods defined' do
    receptacle.strategy Fixtures::User::Strategy::Real
    assert_equal :where, receptacle.where('test')
    assert_raises(NoMethodError) { receptacle.foo }
  end

  describe 'argument passing' do
    before do
      receptacle.strategy Fixtures::User::Strategy::Real
    end

    it 'supports plain argument' do
      receptacle.where('test')
      assert_equal [[Fixtures::User::Strategy::Real, :where, 'test']], callstack
    end

    it 'supports argument through wrappers' do
      receptacle.wrappers [Fixtures::User::Wrappers::ArgumentPasser]
      receptacle.where('test')
      assert_equal [
        [Fixtures::User::Wrappers::ArgumentPasser, :before_where],
        [Fixtures::User::Strategy::Real, :where, 'test']
      ], callstack
    end

    it 'supports array as argument' do
      receptacle.where(['test'])
      assert_equal [[Fixtures::User::Strategy::Real, :where, ['test']]], callstack
    end

    it 'supports array argument through wrappers' do
      receptacle.wrappers [Fixtures::User::Wrappers::ArgumentPasser]
      receptacle.where(['test'])
      assert_equal [
        [Fixtures::User::Wrappers::ArgumentPasser, :before_where],
        [Fixtures::User::Strategy::Real, :where, ['test']]
      ], callstack
    end

    it 'supports kwargs' do
      receptacle.find(foo: 'test', bar: 56)
      assert_equal [
        [Fixtures::User::Strategy::Real, :find, { foo: 'test', bar: 56 }]
      ], callstack
    end

    it 'supports kwargs through wrappers' do
      receptacle.wrappers [Fixtures::User::Wrappers::ArgumentPasser]
      receptacle.find(foo: 'test', bar: 56)
      assert_equal [
        [Fixtures::User::Wrappers::ArgumentPasser, :before_find],
        [Fixtures::User::Strategy::Real, :find, { foo: 'test', bar: 56 }]
      ], callstack
    end

    it 'supports blocks' do
      assert_equal 'test_in_block', receptacle.with(context: 'test') { |c| "#{c}_in_block" }
      assert_equal [
        [Fixtures::User::Strategy::Real, :with, 'test']
      ], callstack
    end

    it 'supports blocks with wrappers' do
      receptacle.wrappers [Fixtures::User::Wrappers::ArgumentPasser]
      assert_equal 'test_in_block', receptacle.with('test') { |c| "#{c}_in_block" }
      assert_equal [
        [Fixtures::User::Wrappers::ArgumentPasser, :before_with],
        [Fixtures::User::Strategy::Real, :with, 'test']
      ], callstack
    end
  end

  describe 'call order' do
    before do
      receptacle.strategy Fixtures::User::Strategy::Fake
    end

    it 'wrappers set to empty array' do
      receptacle.wrappers []
      receptacle.where('test')
      assert_equal [[Fixtures::User::Strategy::Fake, :where, 'test']], callstack
    end

    it 'has only before wrappers' do
      receptacle.wrappers [Fixtures::User::Wrappers::ArgumentPasser]
      receptacle.where('test')
      assert_equal [
        [Fixtures::User::Wrappers::ArgumentPasser, :before_where],
        [Fixtures::User::Strategy::Fake, :where, 'test']
      ], callstack
    end

    it 'has only after wrappers' do
      receptacle.wrappers [Fixtures::User::Wrappers::LogResults]
      receptacle.where('test')
      assert_equal [
        [Fixtures::User::Strategy::Fake, :where, 'test'],
        [Fixtures::User::Wrappers::LogResults, :after_where, :where]
      ], callstack
    end

    it 'calls wrappers correctly' do
      receptacle.wrappers [Fixtures::User::Wrappers::First, Fixtures::User::Wrappers::Second]
      receptacle.where('test')
      assert_equal [[Fixtures::User::Wrappers::First, :before_where],
                    [Fixtures::User::Wrappers::Second, :before_where],
                    [Fixtures::User::Strategy::Fake, :where, 'test'],
                    [Fixtures::User::Wrappers::Second, :after_where],
                    [Fixtures::User::Wrappers::First, :after_where]], callstack
    end

    it 'calls correct wrappers and strategy after switching' do
      receptacle.wrappers [Fixtures::User::Wrappers::First, Fixtures::User::Wrappers::Second]
      receptacle.where('test')
      assert_equal [[Fixtures::User::Wrappers::First, :before_where],
                    [Fixtures::User::Wrappers::Second, :before_where],
                    [Fixtures::User::Strategy::Fake, :where, 'test'],
                    [Fixtures::User::Wrappers::Second, :after_where],
                    [Fixtures::User::Wrappers::First, :after_where]], callstack
      Fixtures::CallStack.instance.stack = []

      receptacle.strategy Fixtures::User::Strategy::Real
      receptacle.wrappers [Fixtures::User::Wrappers::First]
      receptacle.where('test')
      assert_equal [[Fixtures::User::Wrappers::First, :before_where],
                    [Fixtures::User::Strategy::Real, :where, 'test'],
                    [Fixtures::User::Wrappers::First, :after_where]], callstack
    end

    it 'has one wrappers instance per method call' do
      mock = Minitest::Mock.new
      # for method_cache stuff
      mock.expect(:method_defined?, true, [:before_where])
      mock.expect(:method_defined?, true, [:after_where])
      mock.expect(:hash, 1)
      mock.expect(:hash, 1)
      # actual expectation
      mock.expect(:new, Fixtures::User::Wrappers::Second.new)
      receptacle.wrappers mock
      receptacle.where('test')
      mock.verify
    end
  end
end
