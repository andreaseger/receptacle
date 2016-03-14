require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem 'minitest', require: false
end

require "singleton"
module Receptacle
  class Registration
    include Singleton
    attr_accessor :receptacles
    attr_accessor :wrappers
    def initialize
      @receptacles = {}
      @wrappers = {}
    end
  end

  def self.register(receptacle, strategy)
    Registration.instance.receptacles[receptacle] = strategy
  end
  def self.wrappers(receptacle, *wrappers)
    Registration.instance.wrappers[receptacle] = Array(wrappers)
  end

  module Base
    def self.included(base)
      base.extend(ClassMethods)
    end
    module ClassMethods
      def delegate_to_strategy(method_name)
        define_singleton_method(method_name) do |*args|
          strategy = Registration.instance.receptacles.fetch(self) do
            raise "not configured"
          end

          with_wrappers(self, method_name, *args) do |*call_args|
            strategy.new.public_send(method_name, *call_args)
          end
        end
      end
      
      def with_wrappers(base, method_name, *args, &block)
        wrappers = Registration.instance.wrappers[base]
        return block.call(*args) if wrappers.empty?

        wrappers = wrappers.map(&:new)
        *args = before_wrapper(wrappers, method_name, *args)
        ret = block.call(*args)
        after_wrapper(wrappers, method_name, *args, ret)
      end

      def before_wrapper(wrappers, method_name, *args)
        before_method_name = "before_#{method_name}"
        before_wrapper = wrappers.select{|e| e.respond_to?(before_method_name)}
        return *args if before_wrapper.empty?

        before_wrapper.reduce(*args) do |memo, wrapper|
          wrapper.public_send(before_method_name, memo)
        end
      end

      def after_wrapper(wrappers, method_name, *args, return_value)
        after_method_name = "after_#{method_name}"
        after_wrapper  = wrappers.select{|e| e.respond_to?(after_method_name)}.reverse
        return return_value if after_wrapper.empty?

        after_wrapper.reduce(return_value) do |memo, wrapper|
          wrapper.public_send(after_method_name, *args, memo)
        end
      end
    end
  end
end

#--------------- tests -----------------

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
    module Strategy
      class Base
        def clear
          :clear
        end
      end
      class Fake < Base
        def where(args)
          CallStack.instance.stack.push([self.class, __method__])
          :where
        end
      end
      class Real < Base
        def where(args)
          CallStack.instance.stack.push([self.class, __method__])
          :where
        end
      end
    end
    module Wrappers
      class First
        def before_where(args)
          CallStack.instance.stack.push([self.class, __method__])
          args
        end
        def after_where(args, return_values)
          CallStack.instance.stack.push([self.class, __method__])
          return_values
        end
      end
      class Second
        def before_where(args)
          CallStack.instance.stack.push([self.class, __method__])
          args
        end
        def after_where(args, return_values)
          CallStack.instance.stack.push([self.class, __method__])
          return_values
        end
        attr_accessor :state
      end
    end
  end
end

require 'minitest/autorun'

describe Receptacle do
  before do
    TestFixtures::CallStack.instance.stack = []
  end
  describe "#register" do
    it "keeps track of Receptacle - Strategy config" do
      receptacle = TestFixtures::User
      strategy = TestFixtures::User::Strategy::Fake
      Receptacle.register(receptacle, strategy)
      assert_equal Receptacle::Registration.instance.receptacles[receptacle], strategy
    end

    it "keeps track of config after change of strategy" do
      receptacle = TestFixtures::User
      strategy = TestFixtures::User::Strategy::Fake
      Receptacle.register(receptacle, strategy)

      strategy = TestFixtures::User::Strategy::Real
      Receptacle.register(receptacle, strategy)
      assert_equal Receptacle::Registration.instance.receptacles[receptacle], strategy
    end
  end

  describe "" do
    before do
      @receptacle = TestFixtures::User
      Receptacle.register(@receptacle, TestFixtures::User::Strategy::Fake)
    end
    it "calls wrappers correctly" do
      Receptacle.wrappers(@receptacle, TestFixtures::User::Wrappers::First, TestFixtures::User::Wrappers::Second)
      TestFixtures::User.where("test")
      assert_equal TestFixtures::CallStack.instance.stack,
        [[TestFixtures::User::Wrappers::First, :before_where],
         [TestFixtures::User::Wrappers::Second, :before_where],
         [TestFixtures::User::Strategy::Fake, :where],
         [TestFixtures::User::Wrappers::Second, :after_where],
         [TestFixtures::User::Wrappers::First, :after_where]]
    end
    it "has one wrapper instance per method call" do
      mock = Minitest::Mock.new
      mock.expect(:new, TestFixtures::User::Wrappers::Second.new)
      Receptacle.wrappers(@receptacle, mock)
      TestFixtures::User.where("test")
      mock.verify
    end
  end
end
