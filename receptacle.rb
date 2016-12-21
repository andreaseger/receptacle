# frozen_string_literal: true
require 'set'
require 'singleton'
module Receptacle
  class Registration
    include Singleton
    attr_accessor :receptacles
    attr_accessor :wrappers
    attr_accessor :methods
    def initialize
      @receptacles = {}
      @wrappers = {}
      @methods = {}
    end
  end

  def self.register(receptacle, strategy:)
    Registration.instance.receptacles[receptacle] = strategy
    clear_method_cache
  end

  def self.register_wrappers(receptacle, wrappers:)
    Registration.instance.wrappers[receptacle] = Array(wrappers)
    clear_method_cache
  end

  def self.clear_method_cache(receptacle)
    Registration.instance.methods[receptacle]&.each do |method_name|
      next unless receptacle.respond_to?(method_name)
      receptacle.singleton_class.send(:remove_method, method_name)
    end
  end

  module Base
    def self.included(base)
      base.extend(ClassMethods)
    end
    module ClassMethods
      def delegate_to_strategy(method_name)
        Registration.instance.methods[self] ||= Set.new
        Registration.instance.methods[self] << method_name
      end

      def method_missing(method_name, *arguments, &block)
        if Registration.instance.methods[self]&.include?(method_name)
          print_callstack(method_name)
          define_singleton_method(method_name) do |*args, &inner_block|
            strategy = Registration.instance.receptacles.fetch(self) do
              raise 'not configured'
            end

            with_wrappers(self, method_name, *args) do |*call_args|
              strategy.new.public_send(method_name, *call_args, &inner_block)
            end
          end
          public_send(method_name, *arguments, &block)
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        Registration.instance.methods[self]&.include?(method_name) || super
      end

      CallTuple = Struct.new(:klass, :method_name)
      def print_callstack(method_name)
        wrapper = Registration.instance.wrappers[self]
        wrapper = wrapper&.map(&:new)
        before_method_name = :"before_#{method_name}"
        before_wrapper = wrapper&.select { |w| w.respond_to?(before_method_name) }
        before_tuple = before_wrapper&.map { |bw| CallTuple.new(bw.class, before_method_name) }

        after_method_name = :"after_#{method_name}"
        after_wrapper = wrapper&.select { |w| w.respond_to?(after_method_name) }
        after_tuple = after_wrapper&.map { |bw| CallTuple.new(bw.class, after_method_name) }

        strategy_tuple = CallTuple.new(Registration.instance.receptacles.fetch(self), method_name)
        p [before_tuple, strategy_tuple, after_tuple&.reverse].flatten.compact
      end

      def with_wrappers(base, method_name, *input_args)
        wrappers = Registration.instance.wrappers[base]
        return yield(*input_args) if wrappers.nil? || wrappers.empty?

        wrappers = wrappers.map(&:new)
        args = before_wrapper(wrappers, method_name, *input_args)
        ret = yield(args)
        after_wrapper(wrappers, method_name, args, ret)
      end

      def before_wrapper(wrappers, method_name, args)
        before_method_name = "before_#{method_name}"
        before_wrapper = wrappers
                         .select { |e| e.respond_to?(before_method_name) }
        return args if before_wrapper.empty?

        before_wrapper.reduce(args) do |memo, wrapper|
          wrapper.public_send(before_method_name, memo)
        end
      end

      def after_wrapper(wrappers, method_name, *args, return_value)
        after_method_name = "after_#{method_name}"
        after_wrapper = wrappers
                        .select { |e| e.respond_to?(after_method_name) }.reverse
        return return_value if after_wrapper.empty?

        after_wrapper.reduce(return_value) do |memo, wrapper|
          wrapper.public_send(after_method_name, *args, memo)
        end
      end
    end
  end
end
