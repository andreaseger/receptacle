#!/usr/bin/env ruby
# run with --profile.api in JRUBY_OPTS
require 'bundler/inline'
require 'jruby/profiler'
PROFILE_NAME = "receptacle"

gemfile false do
  source 'https://rubygems.org'
  gem 'receptacle', path: './..'
end
require_relative 'user_receptacle'
User.strategy(User::Strategy::Real)
User.wrappers [User::Wrappers::First,
               User::Wrappers::Second,
               User::Wrappers::ArgumentPasser,
               User::Wrappers::LogResults
              ]
User.all(:foo)
User.find(:foo)
User.where(:foo)

GC.disable
profile_data = JRuby::Profiler.profile do
  100_000.times { User.find(:goo) }
end


profile_printer = JRuby::Profiler::GraphProfilePrinter.new(profile_data)
profile_printer.printProfile(File.open("#{PROFILE_NAME}.graph.profile", "w+"))
profile_printer.printProfile(STDOUT)

profile_printer = JRuby::Profiler::FlatProfilePrinter.new(profile_data)
profile_printer.printProfile(File.open("#{PROFILE_NAME}.flat.profile", "w+"))
