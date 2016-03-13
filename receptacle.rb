require 'pry'
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
        define_singleton_method(method_name) do |args|
          strategy = Registration.instance.receptacles.fetch(self) do
            raise "not configured"
          end

          wrappers(self, method_name, args) do |call_args|
            strategy.new.public_send(method_name, call_args)
          end
        end
      end
      def wrappers(base, method_name, args, &block)
        wrappers = Registration.instance.wrappers[base]
        if wrappers.empty?
          block.call(args) 
        else
          wrappers = wrappers.map(&:new)
          call_args = wrappers.reduce(args) do |memo, wrapper|
            wrapper.public_send("before_#{method_name}", memo)
          end
          ret = wrappers.reduce do |memo, wrapper|
            wrapper.public_send("around_#{method_name}", call_args, memo, &block)
          end
          wrappers.reverse.reduce(ret) do |memo, wrapper|
            wrapper.public_send("after_#{method_name}", call_args, memo)
          end
        end
      end
    end
  end
  module Wrapper
    def self.included(base)
      base.extend(ClassMethods)
    end
    def method_missing(method_sym, *args, &block)
      method_name = method_sym.to_s
      unless %w(before after around).any?{|e| method_name.start_with?(e) }
        super
      end
    end

    module ClassMethods
      def before(method_name, &block)
        define_method("before_#{method_name}", &block)
      end
      def around(method_name, &block)
        define_method("before_#{method_name}", &block)
      end
      def after(method_name, &block)
        define_method("before_#{method_name}", &block)
      end
    end
  end
end

module Repo
  module User
    include Receptacle::Base
    delegate_to_strategy :where
    module Strategy
      class Fake
        def where(args)
          p "Fake#where #{args}"
          :where
        end
      end
      class Real
        def where(args)
          p "Real#where #{args}"
        end
      end
    end
    module Wrappers
      class First
        include Receptacle::Wrapper
        before :where do |args|
          puts "First#before"
          args
        end
        # after :where do |args, return_values|
        #   puts "First#after"
        #   return_values
        # end
      end
      class Second
        include Receptacle::Wrapper
        # around :where do |args, ret, &block|
        #   puts "Second#around - before"
        #   ret = block.call(args)
        #   puts "Second#around - after"
        #   ret
        # end
        # before :where do |args|
        #   puts "Second#before"
        #   args
        # end
        # after :where do |args, return_values|
        #   puts "Second#after"
        #   return_values
        # end
      end
    end
  end
end

Receptacle.register(Repo::User, Repo::User::Strategy::Fake)
Receptacle.wrappers(Repo::User, Repo::User::Wrappers::First, Repo::User::Wrappers::Second)
binding.pry
p Repo::User.where(123)
p 'exit'
