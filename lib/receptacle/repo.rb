# frozen_string_literal: true

require "receptacle/errors"

module Receptacle
  module Repo
    module ClassMethods
      def mediate(method_name)
        define_singleton_method(method_name) do |*args, **kwargs|
          raise Errors::NotConfigured.new(repo: self) unless @strategy

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
          wrapper_instance = next_wrapper.new
          if wrapper_instance.respond_to?(method_name)
            wrapper_instance.public_send(method_name, *args, **kwargs) do |*sub_args, **sub_kwargs|
              with_wrappers(wrappers, method_name, *sub_args, **sub_kwargs, &block)
            end
          else
            with_wrappers(wrappers, method_name, *args, **kwargs, &block)
          end
        else
          yield(*args, **kwargs)
        end
      end
    end

    def self.included(base)
      base.instance_variable_set(:@wrappers, [])
      base.extend(ClassMethods)
    end
  end
end
