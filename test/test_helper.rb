# frozen_string_literal: true
require 'simplecov'
if ENV['TRAVIS']
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end
SimpleCov.start do
  add_filter '/test/'
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'receptacle'

require 'minitest/autorun'
