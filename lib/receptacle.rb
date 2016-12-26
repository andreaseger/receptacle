# frozen_string_literal: true
require 'receptacle/version'
module Receptacle
  autoload :Registration, 'receptacle/registration'
  autoload :MethodCache, 'receptacle/method_cache'
  autoload :Base, 'receptacle/base'

  def self.register(receptacle, strategy:)
    Registration.receptacles[receptacle] = strategy
    Registration.clear_method_cache(receptacle)
  end

  def self.register_wrappers(receptacle, wrappers:)
    Registration.wrappers[receptacle] = Array(wrappers)
    Registration.clear_method_cache(receptacle)
  end
end
