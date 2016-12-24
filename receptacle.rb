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
    clear_method_cache(receptacle)
  end

  def self.register_wrappers(receptacle, wrappers:)
    Registration.instance.wrappers[receptacle] = Array(wrappers)
    clear_method_cache(receptacle)
  end

  # {clear_method_cache} removes dynamically defined methods
  # this is needed to make strategy and wrappers changes inside the codebase possible
  def self.clear_method_cache(receptacle)
    Registration.instance.methods[receptacle]&.each do |method_name|
      begin
        receptacle.singleton_class.send(:remove_method, method_name)
        # TODO: just a temporary thing
        receptacle.singleton_class.send(:remove_method, :"#{method_name}_cached")
      rescue
        nil
      end
    end
  end

  class MethodCallCache
    attr_reader :strategy, :wrappers, :before_method_name, :after_method_name

    def initialize(strategy:, before_wrappers:, after_wrappers:, method_name:)
      @strategy = strategy
      @before_wrappers = before_wrappers || []
      @after_wrappers = after_wrappers || []
      @wrappers = @before_wrappers | @after_wrappers
      @before_method_name = :"before_#{method_name}"
      @after_method_name = :"after_#{method_name}"
    end

    def skip_before_wrappers?
      @before_wrappers.empty?
    end

    def skip_after_wrappers?
      @after_wrappers.empty?
    end
  end

  CallTuple = Struct.new(:klass, :method_name)
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
          build_method(method_name)
          build_cached_method(method_name)
          public_send("#{method_name}_cached", *arguments, &block)
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        super
        Registration.instance.methods[self]&.include?(method_name) || super
      end

      def build_method_call_cache(method_name)
        wrappers = Registration.instance.wrappers[self]
        before_method_name = :"before_#{method_name}"
        after_method_name = :"after_#{method_name}"

        MethodCallCache.new(
          strategy: Registration.instance.receptacles.fetch(self) { raise 'not configured' },
          before_wrappers: wrappers&.select { |w| w.method_defined?(before_method_name) },
          after_wrappers: wrappers&.select { |w| w.method_defined?(after_method_name) },
          method_name: method_name
        )
      end

      def build_cached_method(method_name)
        method_call_cache = build_method_call_cache(method_name)
        define_singleton_method("#{method_name}_cached") do |*args, &inner_block|
          run_wrappers(method_call_cache, *args) do |*call_args|
            method_call_cache.strategy.new.public_send(method_name, *call_args, &inner_block)
          end
        end
      end

      def run_wrappers(method_call_cache, *input_args)
        wrappers = method_call_cache.wrappers
        return yield(*input_args) if wrappers.nil? || wrappers.empty?

        wrappers = wrappers.map(&:new)
        # TODO: this next line seems like a workaround
        bw = method_call_cache.skip_before_wrappers? ? [] : wrappers
        args = run_before_wrappers(bw, method_call_cache.before_method_name, *input_args)
        ret = yield(args)
        return ret if method_call_cache.skip_after_wrappers?
        run_after_wrappers(wrappers, method_call_cache.after_method_name, args, ret)
      end

      #-------------------------------------------------------------------------#

      def build_method(method_name)
        define_singleton_method(method_name) do |*args, &inner_block|
          strategy = Registration.instance.receptacles.fetch(self) do
            raise 'not configured'
          end

          with_wrappers(self, method_name, *args) do |*call_args|
            strategy.new.public_send(method_name, *call_args, &inner_block)
          end
        end
      end

      def with_wrappers(base, method_name, *input_args)
        wrappers = Registration.instance.wrappers[base]
        return yield(*input_args) if wrappers.nil? || wrappers.empty?

        wrappers = wrappers.map(&:new)
        args = run_before_wrappers(wrappers, "before_#{method_name}", *input_args)
        ret = yield(args)
        run_after_wrappers(wrappers, "after_#{method_name}", args, ret)
      end

      def run_before_wrappers(wrappers, method_name, args)
        before_wrappers = wrappers
                          .select { |w| w.respond_to?(method_name) }
        return args if before_wrappers.empty?

        before_wrappers.reduce(args) do |memo, wrapper|
          wrapper.public_send(method_name, memo)
        end
      end

      def run_after_wrappers(wrappers, method_name, args, return_value)
        after_wrappers = wrappers
                         .select { |w| w.respond_to?(method_name) }
        return return_value if after_wrappers.empty?

        after_wrappers.reverse.reduce(return_value) do |memo, wrapper|
          wrapper.public_send(method_name, args, memo)
        end
      end
    end
  end
end
