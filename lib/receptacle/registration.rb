# frozen_string_literal: true
require 'singleton'
require 'set'
module Receptacle
  class Registration
    include Singleton
    Tuple = Struct.new(:strategy, :wrappers, :methods)

    attr_reader :repos

    def initialize
      @repos = Hash.new do |h, k|
        h[k] = Tuple.new(nil, [], Set.new)
      end
    end

    def self.repos
      instance.repos
    end

    # {clear_method_cache} removes dynamically defined methods
    # this is needed to make strategy and wrappers changes inside the codebase possible
    def self.clear_method_cache(receptacle)
      instance.repos[receptacle].methods.each do |method_name|
        begin
          receptacle.singleton_class.send(:remove_method, method_name)
        rescue NameError
          # TODO
          # p receptacle.method_defined?(method_name)
          nil
        end
      end
    end
  end
end
