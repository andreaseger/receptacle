# frozen_string_literal: true
require 'singleton'
module Receptacle
  class Registration
    include Singleton
    attr_reader :receptacles
    attr_reader :wrappers
    attr_reader :methods
    def initialize
      @receptacles = {}
      @wrappers = {}
      @methods = {}
    end

    def self.wrappers
      instance.wrappers
    end

    def self.receptacles
      instance.receptacles
    end

    def self.methods
      instance.methods
    end

    # {clear_method_cache} removes dynamically defined methods
    # this is needed to make strategy and wrappers changes inside the codebase possible
    def self.clear_method_cache(receptacle)
      instance.methods[receptacle]&.each do |method_name|
        begin
          receptacle.singleton_class.send(:remove_method, method_name)
          # TODO: just a temporary thing
          receptacle.singleton_class.send(:remove_method, :"#{method_name}_cached")
        rescue
          nil
        end
      end
    end
  end
end
