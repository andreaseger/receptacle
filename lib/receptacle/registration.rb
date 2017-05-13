# frozen_string_literal: true

require 'singleton'
require 'set'
module Receptacle
  # keeps global state of repositories, the defined strategy, set wrappers and methods to mediate
  class Registration
    include Singleton
    Tuple = Struct.new(:strategy, :wrappers, :methods)

    attr_reader :repositories

    def initialize
      @repositories = Hash.new do |h, k|
        h[k] = Tuple.new(nil, [], Set.new)
      end
    end

    def self.repositories
      instance.repositories
    end

    # {clear_method_cache} removes dynamically defined methods
    # this is needed to make strategy and wrappers changes inside the codebase possible
    def self.clear_method_cache(receptacle)
      instance.repositories[receptacle].methods.each do |method_name|
        begin
          receptacle.singleton_class.send(:remove_method, method_name)
        rescue NameError
          nil
        end
      end
    end
  end
end
