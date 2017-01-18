# frozen_string_literal: true
require 'receptacle/version'
require 'receptacle/interface_methods'
require 'receptacle/method_delegation'

module Receptacle
  def self.included(base)
    base.extend(InterfaceMethods)
    base.extend(MethodDelegation)
  end
end
