# frozen_string_literal: true

unless RUBY_PLATFORM == "java"
  require "simplecov"
  SimpleCov.start do
    add_filter "/test/"
  end
end

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "receptacle"

require "minitest/autorun"
