# frozen_string_literal: true
unless RUBY_PLATFORM == 'java'
  require 'simplecov'
  require 'simplecov-json'
  if ENV['TRAVIS']
    require 'codecov'
    SimpleCov.formatters = [
      SimpleCov::Formatter::Codecov,
      SimpleCov::Formatter::JSONFormatter
    ]
  else
    SimpleCov.formatters = [
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::JSONFormatter
    ]

  end
  SimpleCov.start do
    add_filter '/test/'
  end
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'receptacle'

require 'minitest/autorun'
