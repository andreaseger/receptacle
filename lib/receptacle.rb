# frozen_string_literal: true

require "receptacle/version"
require "receptacle/repository"

module Receptacle
  module Repo
    module ClassMethods
      def mediate(method_name)
        define_singleton_method(method_name) do |*args, **kwargs|
          raise NotConfigured unless @strategy

          with_wrappers(@wrappers.dup, method_name, *args, **kwargs) do |*sub_args, **sub_kwargs|
            strategy.new.public_send(method_name, *sub_args, **sub_kwargs)
          end
        end
      end

      def wrappers(wrappers)
        @wrappers = wrappers
      end

      def strategy(value = nil)
        if value
          @strategy = value
        else
          @strategy
        end
      end

      def with_wrappers(wrappers, method_name, *args, **kwargs, &block)
        next_wrapper = wrappers.shift
        if next_wrapper
          next_wrapper.new.public_send(method_name, *args, **kwargs) do |*sub_args, **sub_kwargs|
            with_wrappers(wrappers, method_name, *sub_args, **sub_kwargs, &block)
          end
        else
          yield(*args, **kwargs)
        end
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
