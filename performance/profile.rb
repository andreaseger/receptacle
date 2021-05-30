#!/usr/bin/env ruby
# frozen_string_literal: true

# run with --profile.api in JRUBY_OPTS
require "bundler/inline"
require "jruby/profiler"
PROFILE_NAME = "receptacle"

gemfile false do
  source "https://rubygems.org"
  gem "receptacle", path: "./.."
end
require_relative "speed_receptacle"

Speed.strategy(Speed::Strategy::One)
Speed.wrappers [Speed::Wrappers::W1,
  Speed::Wrappers::W2,
  Speed::Wrappers::W3,
  Speed::Wrappers::W4,
  Speed::Wrappers::W5,
  Speed::Wrappers::W6]
Speed.a(1)
Speed.b(1)
Speed.c(1)
Speed.d(1)
Speed.e(1)
Speed.f(1)
Speed.g(1)

GC.disable
profile_data = JRuby::Profiler.profile do
  100_000.times { Speed.a(1) }
end

profile_printer = JRuby::Profiler::GraphProfilePrinter.new(profile_data)
profile_printer.printProfile(File.open("#{PROFILE_NAME}.graph.profile", "w+"))
profile_printer.printProfile($stdout)

profile_printer = JRuby::Profiler::FlatProfilePrinter.new(profile_data)
profile_printer.printProfile(File.open("#{PROFILE_NAME}.flat.profile", "w+"))
