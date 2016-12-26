# frozen_string_literal: true
module Receptacle
  class MethodCache
    attr_reader :strategy, :wrappers, :before_method_name, :after_method_name, :method_name

    def initialize(strategy:, before_wrappers:, after_wrappers:, method_name:)
      @strategy = strategy
      @before_method_name = :"before_#{method_name}"
      @after_method_name = :"after_#{method_name}"
      @method_name = method_name
      before_wrappers ||= []
      after_wrappers ||= []
      @wrappers = before_wrappers | after_wrappers
      @skip_before_wrappers = before_wrappers.empty?
      @skip_after_wrappers = after_wrappers.empty?
    end

    def skip_before_wrappers?
      @skip_before_wrappers
    end

    def skip_after_wrappers?
      @skip_after_wrappers
    end
  end
end
