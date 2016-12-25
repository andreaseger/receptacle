# frozen_string_literal: true
require 'bundler/inline'

gemfile false do
  source 'https://rubygems.org'
  gem 'benchmark-ips'
  gem "receptacle", path: "./.."
end

module Bench
  include Receptacle::Base
  delegate_to_strategy :find
  delegate_to_strategy :where
  delegate_to_strategy :all
  module Strategy
    class Real
      def find(arg)
        arg
      end

      def where(args)
        args
      end

      def all(args)
        args
      end
    end
  end

  module Wrappers
    class First
      def before_where(args)
        args
      end

      def after_where(_args, return_values)
        return_values
      end
    end
    class Second
      def before_where(args)
        args
      end

      def after_where(_args, return_values)
        return_values
      end
      attr_accessor :state
    end
    class ArgumentPasser
      def before_where(args)
        args
      end

      def before_find(args)
        args
      end

      def before_with(context)
        { context: context }
      end

      def after_meh; end
    end
    class LogResults
      def before_find(args)
        args
      end

      def after_where(_, return_values)
        return_values
      end
    end
  end
end

Receptacle.register(Bench, strategy: Bench::Strategy::Real)
Receptacle.register_wrappers(Bench, wrappers: [
                               Bench::Wrappers::First,
                               Bench::Wrappers::Second,
                               Bench::Wrappers::ArgumentPasser,
                               Bench::Wrappers::LogResults
                             ])

print ":where method - all 4 wrappers have at least one wrapper method\n"
Benchmark.ips do |x|
  x.warmup = 10 if RUBY_ENGINE == 'jruby'
  x.report('baseline') { Bench.where(:foo) }
  x.report('w/ method cache') { Bench.where_cached(:foo) }
  x.compare!
end

print ":find method - only 2 wrappers have at least one wrapper method\n"
Benchmark.ips do |x|
  x.warmup = 10 if RUBY_ENGINE == 'jruby'
  x.report('baseline') { Bench.find(:foo) }
  x.report('w/ method cache') { Bench.find_cached(:foo) }
  x.compare!
end

print ":all method - no wrapper has a wrapper method for this method\n"
Benchmark.ips do |x|
  x.warmup = 10 if RUBY_ENGINE == 'jruby'
  x.report('baseline') { Bench.all(:foo) }
  x.report('w/ method cache') { Bench.all_cached(:foo) }
  x.compare!
end

Receptacle.register_wrappers(Bench, wrappers: [])
print "no wrappers configured\n"
Benchmark.ips do |x|
  x.warmup = 10 if RUBY_ENGINE == 'jruby'
  x.report('baseline') { Bench.all(:foo) }
  x.report('w/ method cache') { Bench.all_cached(:foo) }
  # x.report("direct calls") { Bench::Strategy::Real.new.all(:foo)}
  x.compare!
end
