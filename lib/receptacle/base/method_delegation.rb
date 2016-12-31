# frozen_string_literal: true
require 'receptacle/method_cache'
require 'receptacle/registration'
require 'receptacle/errors'

module Receptacle
  module Base
    module MethodDelegation
      def method_missing(method_name, *arguments, &block)
        if Registration.repos[self].methods.include?(method_name)
          public_send(__build_method(method_name), *arguments, &block)
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        super
        Registration.repos[self].methods.include?(method_name) || super
      end

      def __build_method_call_cache(method_name)
        config = Registration.repos[self]
        before_method_name = :"before_#{method_name}"
        after_method_name = :"after_#{method_name}"

        raise Errors::NotConfigured, repo: self if config.strategy.nil?
        MethodCache.new(
          strategy: config.strategy,
          before_wrappers: config.wrappers.select { |w| w.method_defined?(before_method_name) },
          after_wrappers: config.wrappers.select { |w| w.method_defined?(after_method_name) },
          method_name: method_name
        )
      end

      def __build_method(method_name)
        method_cache = __build_method_call_cache(method_name)
        if method_cache.wrappers.nil? || method_cache.wrappers.empty?
          __define_shortcut_method(method_name, method_cache)
        else
          __define_full_method(method_name, method_cache)
        end
      end

      def __define_shortcut_method(method_name, method_cache)
        define_singleton_method(method_name) do |*args, &inner_block|
          method_cache.strategy.new.public_send(method_name, *args, &inner_block)
        end
      end

      def __define_full_method(method_name, method_cache)
        define_singleton_method(method_name) do |*args, &inner_block|
          __run_wrappers(method_cache, *args) do |*call_args|
            method_cache.strategy.new.public_send(method_name, *call_args, &inner_block)
          end
        end
      end

      def __run_wrappers(method_cache, input_args)
        wrappers = method_cache.wrappers.map(&:new)
        args = if method_cache.skip_before_wrappers?
                 input_args
               else
                 __run_before_wrappers(wrappers, method_cache.before_method_name, input_args)
               end
        ret = yield(args)
        return ret if method_cache.skip_after_wrappers?
        __run_after_wrappers(wrappers, method_cache.after_method_name, args, ret)
      end

      def __run_before_wrappers(wrappers, method_name, args)
        before_wrappers = wrappers
                          .select { |w| w.respond_to?(method_name) }

        before_wrappers.reduce(args) do |memo, wrapper|
          wrapper.public_send(method_name, memo)
        end
      end

      def __run_after_wrappers(wrappers, method_name, args, return_value)
        after_wrappers = wrappers
                         .select { |w| w.respond_to?(method_name) }

        after_wrappers.reverse.reduce(return_value) do |memo, wrapper|
          wrapper.public_send(method_name, args, memo)
        end
      end
    end
  end
end
