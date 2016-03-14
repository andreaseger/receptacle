require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem 'pry'
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

  def self.register(repository, strategy)
    Registration.instance.receptacles[repository] = strategy
  end
  def self.wrappers(repository, *wrappers)
    Registration.instance.wrappers[repository] = Array(wrappers)
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

module Foo
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
          puts "Fake#where #{args}"
          :where
        end
      end
      class Real < Base
        def where(args)
          puts "Real#where #{args}"
          :where
        end
      end
    end
    module Wrappers
      class First
        def before_where(args)
          puts "First#before"
          args
        end
        def after_where(args, return_values)
          puts "First#after"
          return_values
        end
      end
      class Second
        def before_where(args)
          puts "Second#before"
          self.state = 24
          args
        end
        def after_where(args, return_values)
          puts "Second#after with around state: #{state}"
          return_values
        end
        attr_accessor :state
      end
    end
  end
end

Receptacle.register(Foo::User, Foo::User::Strategy::Fake)
Receptacle.wrappers(Foo::User, Foo::User::Wrappers::First, Foo::User::Wrappers::Second)
puts Foo::User.where(123)
puts Foo::User.clear
puts "------------change strategy --------------"
Receptacle.register(Foo::User, Foo::User::Strategy::Real)
puts Foo::User.where(123)
puts Foo::User.clear
