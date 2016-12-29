# frozen_string_literal: true
require 'receptacle/registration'
require 'receptacle/base/method_delegation'
require 'receptacle/errors'

module Receptacle
  RESERVED_METHOD_NAMES = Set.new(%i(wrapper mediate strategy))
  module Base
    def self.included(base)
      base.extend(ClassMethods)
      base.extend(MethodDelegation)
    end
    module ClassMethods
      def mediate(method_name)
        raise Errors::ReservedMethodName if RESERVED_METHOD_NAMES.include?(method_name)
        Registration.repos[self].methods << method_name
      end

      def strategy(value = nil)
        if value
          Registration.repos[self].strategy = value
          Registration.clear_method_cache(self)
        else
          Registration.repos[self].strategy
        end
      end

      def wrappers(value = nil)
        if value
          Registration.repos[self].wrappers = Array(value)
          Registration.clear_method_cache(self)
        else
          Registration.repos[self].wrappers
        end
      end
    end
  end
end
