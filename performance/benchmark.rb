# frozen_string_literal: true
require 'bundler/inline'

gemfile false do
  source 'https://rubygems.org'
  gem 'benchmark-ips'
  gem 'receptacle', path: './..'
end

require_relative "user_receptacle"

User.strategy(User::Strategy::Real)
User.wrappers [User::Wrappers::First,
                User::Wrappers::Second,
                User::Wrappers::ArgumentPasser,
                User::Wrappers::LogResults
               ]

# print ":where method - all 4 wrappers have at least one wrapper method\n"
# Benchmark.ips do |x|
#   x.warmup = 10 if RUBY_ENGINE == 'jruby'
#   x.report('baseline') { User.where(:foo) }
#   x.report('w/ method proc') { User.where_cached(:foo) }
#   x.compare!
# end

# print ":find method - only 2 wrappers have at least one wrapper method\n"
# Benchmark.ips do |x|
#   x.warmup = 10 if RUBY_ENGINE == 'jruby'
#   x.report('baseline') { User.find(:foo) }
#   x.report('direct call') do
#     User::Strategy::Real.new.public_send(:all,
#                                    User::Wrappers::LogResults.new.before_find(
#                                      User::Wrappers::ArgumentPasser.new.before_find(:foo)))
#   end
#   x.compare!
# end

# print ":all method - no wrapper has a wrapper method for this method\n"
# Benchmark.ips do |x|
#   x.warmup = 10 if RUBY_ENGINE == 'jruby'
#   x.report('baseline') { User.all(:foo) }
#   x.report('direct call') { User::Strategy::Real.new.public_send(:all, :foo)}
#   x.compare!
# end

User.wrappers []
print "no wrappers configured\n"
Benchmark.ips do |x|
  x.warmup = 10 if RUBY_ENGINE == 'jruby'
  # x.report('baseline') { User.all(:foo) }
  x.report("public_send") { User::Strategy::Real.new.public_send(:all, :foo) }
  x.report("via method") do
    m = User::Strategy::Real.new.method(:all)
    m.call(:foo)
  end
  x.report("direct call") { User::Strategy::Real.new.all(:foo) }
  x.compare!
end
