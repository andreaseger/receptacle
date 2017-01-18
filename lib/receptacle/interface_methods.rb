# frozen_string_literal: true
require 'receptacle/registration'
require 'receptacle/errors'

module Receptacle
  module InterfaceMethods
    RESERVED_METHOD_NAMES = Set.new(%i(wrappers mediate strategy delegate_to_strategy))
    private_constant :RESERVED_METHOD_NAMES

    # registers a method_name for the to be mediated or forwarded to the configured strategy
    #
    # @param method_name [String] name of method to register
    def mediate(method_name)
      raise Errors::ReservedMethodName if RESERVED_METHOD_NAMES.include?(method_name)
      Registration.repositories[self].methods << method_name
    end
    alias delegate_to_strategy mediate

    # get or sets the strategy
    #
    # @note will set the strategy for this receptacle if passed in; will only
    #      return the current strategy if nil or no parameter passed include
    # @param value [Class,nil]
    # @return [Class] current configured strategy class
    def strategy(value = nil)
      if value
        Registration.repositories[self].strategy = value
        Registration.clear_method_cache(self)
      else
        Registration.repositories[self].strategy
      end
    end

    # get or sets the wrappers
    #
    # @note will set the wrappers for this receptacle if passed in; will only
    #      return the current wrappers if nil or no parameter passed include
    # @param value [Class,Array(Class),nil] wrappers
    # @return [Array(Class)] current configured wrappers
    def wrappers(value = nil)
      if value
        Registration.repositories[self].wrappers = Array(value)
        Registration.clear_method_cache(self)
      else
        Registration.repositories[self].wrappers
      end
    end
  end
end
