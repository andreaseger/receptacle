# frozen_string_literal: true
require './receptacle'

module TestFixtures
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

require 'minitest/autorun'

describe Receptacle do
  def callstack
    TestFixtures::CallStack.instance.stack
  end

  def receptacle
    TestFixtures::User
  end
  before do
    Receptacle::Registration.instance.receptacles = {}
    Receptacle::Registration.instance.wrappers = {}
    TestFixtures::CallStack.instance.stack = []
    Receptacle::Registration.instance.methods[receptacle]&.each do |method_name|
      begin
        receptacle.send(:remove_method, method_name)
      rescue
        nil
      end
    end
  end
  describe '#register' do
    it 'keeps track of Receptacle - Strategy config' do
      strategy = TestFixtures::User::Strategy::Fake
      Receptacle.register(receptacle, strategy: strategy)
      assert_equal Receptacle::Registration.instance.receptacles[receptacle],
                   strategy
    end

    it 'keeps track of config after change of strategy' do
      strategy = TestFixtures::User::Strategy::Fake
      Receptacle.register(receptacle, strategy: strategy)

      strategy = TestFixtures::User::Strategy::Real
      Receptacle.register(receptacle, strategy: strategy)
      assert_equal Receptacle::Registration.instance.receptacles[receptacle],
                   strategy
    end
  end

  describe 'argument passing' do
    before do
      Receptacle.register(receptacle, strategy: TestFixtures::User::Strategy::Real)
    end

    it 'can supports plain argument' do
      receptacle.where('test')
      assert_equal callstack, [[TestFixtures::User::Strategy::Real, :where, 'test']]
    end
    it 'can supports plain argument through wrapper' do
      Receptacle.register_wrappers(receptacle, wrappers: [TestFixtures::User::Wrappers::ArgumentPasser])
      receptacle.where('test')
      assert_equal callstack, [
        [TestFixtures::User::Wrappers::ArgumentPasser, :before_where],
        [TestFixtures::User::Strategy::Real, :where, 'test']
      ]
    end

    it 'can supports array as argument' do
      receptacle.where(['test'])
      assert_equal callstack, [[TestFixtures::User::Strategy::Real, :where, ['test']]]
    end
    it 'can supports array argument through wrapper' do
      Receptacle.register_wrappers(receptacle, wrappers: [TestFixtures::User::Wrappers::ArgumentPasser])
      receptacle.where(['test'])
      assert_equal callstack, [
        [TestFixtures::User::Wrappers::ArgumentPasser, :before_where],
        [TestFixtures::User::Strategy::Real, :where, ['test']]
      ]
    end
    it 'can supports kwargs' do
      receptacle.find(foo: 'test', bar: 56)
      assert_equal callstack, [
        [TestFixtures::User::Strategy::Real, :find, { foo: 'test', bar: 56 }]
      ]
    end
    it 'can supports kwargs through wrapper' do
      Receptacle.register_wrappers(receptacle, wrappers: [TestFixtures::User::Wrappers::ArgumentPasser])
      receptacle.find(foo: 'test', bar: 56)
      assert_equal callstack, [
        [TestFixtures::User::Wrappers::ArgumentPasser, :before_find],
        [TestFixtures::User::Strategy::Real, :find, { foo: 'test', bar: 56 }]
      ]
    end

    it 'can support blocks' do
      assert_equal 'test_in_block', receptacle.with(context: 'test') { |c| "#{c}_in_block" }
      assert_equal callstack, [
        [TestFixtures::User::Strategy::Real, :with, 'test']
      ]
    end

    it 'can support blocks with wrappers' do
      Receptacle.register_wrappers(receptacle, wrappers: [TestFixtures::User::Wrappers::ArgumentPasser])
      assert_equal 'test_in_block', receptacle.with('test') { |c| "#{c}_in_block" }
      assert_equal callstack, [
        [TestFixtures::User::Wrappers::ArgumentPasser, :before_with],
        [TestFixtures::User::Strategy::Real, :with, 'test']
      ]
    end
  end

  describe 'call order' do
    before do
      Receptacle.register(receptacle, strategy: TestFixtures::User::Strategy::Fake)
    end
    it 'wrapper set to empty array' do
      Receptacle.register_wrappers(receptacle, wrappers: [])
      receptacle.where('test')
      assert_equal callstack, [[TestFixtures::User::Strategy::Fake, :where, 'test']]
    end

    it 'has only before wrapper' do
      Receptacle.register_wrappers(receptacle, wrappers: [TestFixtures::User::Wrappers::ArgumentPasser])
      receptacle.where('test')
      assert_equal callstack, [
        [TestFixtures::User::Wrappers::ArgumentPasser, :before_where],
        [TestFixtures::User::Strategy::Fake, :where, 'test']
      ]
    end
    it 'has only after wrapper' do
      Receptacle.register_wrappers(receptacle, wrappers: [TestFixtures::User::Wrappers::LogResults])
      receptacle.where('test')
      assert_equal callstack, [
        [TestFixtures::User::Strategy::Fake, :where, 'test'],
        [TestFixtures::User::Wrappers::LogResults, :after_where, :where]
      ]
    end
    it 'calls wrappers correctly' do
      Receptacle.register_wrappers(receptacle, wrappers:
                                         [TestFixtures::User::Wrappers::First,
                                          TestFixtures::User::Wrappers::Second])
      receptacle.where('test')
      assert_equal TestFixtures::CallStack.instance.stack,
                   [[TestFixtures::User::Wrappers::First, :before_where],
                    [TestFixtures::User::Wrappers::Second, :before_where],
                    [TestFixtures::User::Strategy::Fake, :where, 'test'],
                    [TestFixtures::User::Wrappers::Second, :after_where],
                    [TestFixtures::User::Wrappers::First, :after_where]]
    end
    it 'has one wrapper instance per method call' do
      skip('not working because wip callstack caching')
      mock = Minitest::Mock.new
      mock.expect(:new, TestFixtures::User::Wrappers::Second.new)
      Receptacle.register_wrappers(receptacle, wrappers: [mock])
      TestFixtures::User.where('test')
      mock.verify
    end
  end
end
