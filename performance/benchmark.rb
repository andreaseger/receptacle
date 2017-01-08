# frozen_string_literal: true
require 'bundler/inline'

gemfile false do
  source 'https://rubygems.org'
  gem 'benchmark-ips'
  gem 'receptacle', path: './..'
end

require_relative 'speed_receptacle'

Speed.strategy(Speed::Strategy::One)
Speed.wrappers [Speed::Wrappers::W1,
                Speed::Wrappers::W2,
                Speed::Wrappers::W3,
                Speed::Wrappers::W4,
                Speed::Wrappers::W5,
                Speed::Wrappers::W6]

print 'w/ wrappers'
Benchmark.ips do |x|
  x.warmup = 10 if RUBY_ENGINE == 'jruby'
  x.report('a: 1x around, 1x before, 1x after') { Speed.a(1) }
  x.report('b: 1x around, 1x before, 1x after') { Speed.b(1) }
  x.report('c: 1x before, 1x after') { Speed.c(1) }
  x.report('d: 1x after') { Speed.d(1) }
  x.report('e: 1x before') { Speed.e(1) }
  x.report('f: 1x around') { Speed.f(1) }
  x.report('g: no wrappers') { Speed.g(1) }
  x.compare!
end

Speed.wrappers []
print 'method dispatching w/ wrappers'
Benchmark.ips do |x|
  x.warmup = 10 if RUBY_ENGINE == 'jruby'
  x.report('via receptacle') { Speed.a(:foo) }
  x.report('direct via public_send') { Speed::Strategy::One.new.public_send(:a, :foo) }
  x.report('direct via method-method') do
    m = Speed::Strategy::One.new.method(:a)
    m.call(:foo)
  end
  x.report('direct method-call') { Speed::Strategy::One.new.a(:foo) }
  x.compare!
end
