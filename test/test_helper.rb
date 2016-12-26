# frozen_string_literal: true
if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_filter '/test/'
  end
end
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'receptacle'

require 'minitest/autorun'
