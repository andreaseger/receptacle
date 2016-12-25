# frozen_string_literal: true
require "test_helper"
require 'fixture'

describe Receptacle do
  def callstack
    Fixtures::CallStack.instance.stack
  end

  def receptacle
    Fixtures::User
  end
  before do
    Receptacle::Registration.instance.receptacles = {}
    Receptacle::Registration.instance.wrappers = {}
    Fixtures::CallStack.instance.stack = []
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
      strategy = Fixtures::User::Strategy::Fake
      Receptacle.register(receptacle, strategy: strategy)
      assert_equal Receptacle::Registration.instance.receptacles[receptacle],
                   strategy
    end

    it 'keeps track of config after change of strategy' do
      strategy = Fixtures::User::Strategy::Fake
      Receptacle.register(receptacle, strategy: strategy)

      strategy = Fixtures::User::Strategy::Real
      Receptacle.register(receptacle, strategy: strategy)
      assert_equal Receptacle::Registration.instance.receptacles[receptacle],
                   strategy
    end
  end

  describe 'argument passing' do
    before do
      Receptacle.register(receptacle, strategy: Fixtures::User::Strategy::Real)
    end

    it 'can supports plain argument' do
      receptacle.where('test')
      assert_equal callstack, [[Fixtures::User::Strategy::Real, :where, 'test']]
    end
    it 'can supports plain argument through wrapper' do
      Receptacle.register_wrappers(receptacle, wrappers: [Fixtures::User::Wrappers::ArgumentPasser])
      receptacle.where('test')
      assert_equal callstack, [
        [Fixtures::User::Wrappers::ArgumentPasser, :before_where],
        [Fixtures::User::Strategy::Real, :where, 'test']
      ]
    end

    it 'can supports array as argument' do
      receptacle.where(['test'])
      assert_equal callstack, [[Fixtures::User::Strategy::Real, :where, ['test']]]
    end
    it 'can supports array argument through wrapper' do
      Receptacle.register_wrappers(receptacle, wrappers: [Fixtures::User::Wrappers::ArgumentPasser])
      receptacle.where(['test'])
      assert_equal callstack, [
        [Fixtures::User::Wrappers::ArgumentPasser, :before_where],
        [Fixtures::User::Strategy::Real, :where, ['test']]
      ]
    end
    it 'can supports kwargs' do
      receptacle.find(foo: 'test', bar: 56)
      assert_equal callstack, [
        [Fixtures::User::Strategy::Real, :find, { foo: 'test', bar: 56 }]
      ]
    end
    it 'can supports kwargs through wrapper' do
      Receptacle.register_wrappers(receptacle, wrappers: [Fixtures::User::Wrappers::ArgumentPasser])
      receptacle.find(foo: 'test', bar: 56)
      assert_equal callstack, [
        [Fixtures::User::Wrappers::ArgumentPasser, :before_find],
        [Fixtures::User::Strategy::Real, :find, { foo: 'test', bar: 56 }]
      ]
    end

    it 'can support blocks' do
      assert_equal 'test_in_block', receptacle.with(context: 'test') { |c| "#{c}_in_block" }
      assert_equal callstack, [
        [Fixtures::User::Strategy::Real, :with, 'test']
      ]
    end

    it 'can support blocks with wrappers' do
      Receptacle.register_wrappers(receptacle, wrappers: [Fixtures::User::Wrappers::ArgumentPasser])
      assert_equal 'test_in_block', receptacle.with('test') { |c| "#{c}_in_block" }
      assert_equal callstack, [
        [Fixtures::User::Wrappers::ArgumentPasser, :before_with],
        [Fixtures::User::Strategy::Real, :with, 'test']
      ]
    end
  end

  describe 'call order' do
    before do
      Receptacle.register(receptacle, strategy: Fixtures::User::Strategy::Fake)
    end
    it 'wrapper set to empty array' do
      Receptacle.register_wrappers(receptacle, wrappers: [])
      receptacle.where('test')
      assert_equal callstack, [[Fixtures::User::Strategy::Fake, :where, 'test']]
    end

    it 'has only before wrapper' do
      Receptacle.register_wrappers(receptacle, wrappers: [Fixtures::User::Wrappers::ArgumentPasser])
      receptacle.where('test')
      assert_equal callstack, [
        [Fixtures::User::Wrappers::ArgumentPasser, :before_where],
        [Fixtures::User::Strategy::Fake, :where, 'test']
      ]
    end
    it 'has only after wrapper' do
      Receptacle.register_wrappers(receptacle, wrappers: [Fixtures::User::Wrappers::LogResults])
      receptacle.where('test')
      assert_equal callstack, [
        [Fixtures::User::Strategy::Fake, :where, 'test'],
        [Fixtures::User::Wrappers::LogResults, :after_where, :where]
      ]
    end
    it 'calls wrappers correctly' do
      Receptacle.register_wrappers(receptacle, wrappers:
                                         [Fixtures::User::Wrappers::First,
                                          Fixtures::User::Wrappers::Second])
      receptacle.where('test')
      assert_equal callstack,
                   [[Fixtures::User::Wrappers::First, :before_where],
                    [Fixtures::User::Wrappers::Second, :before_where],
                    [Fixtures::User::Strategy::Fake, :where, 'test'],
                    [Fixtures::User::Wrappers::Second, :after_where],
                    [Fixtures::User::Wrappers::First, :after_where]]
    end
    it 'has one wrapper instance per method call' do
      skip("doesn't work this way in the cached calls")
      mock = Minitest::Mock.new
      mock.expect(:new, Fixtures::User::Wrappers::Second.new)
      Receptacle.register_wrappers(receptacle, wrappers: [mock])
      Fixtures::User.where('test')
      mock.verify
    end
  end
end
