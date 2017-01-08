# coding: utf-8
# frozen_string_literal: true
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'receptacle/version'

Gem::Specification.new do |spec|
  spec.name          = 'receptacle'
  spec.version       = Receptacle::VERSION
  spec.authors       = ['Andreas Eger']
  spec.email         = ['dev@eger-andreas.de']

  spec.summary       = 'repository pattern'
  spec.description   = 'provides functionality for the repository or strategy pattern'
  spec.homepage      = 'https://github.com/andreaseger/receptacle'
  spec.license       = 'MIT'

  spec.required_ruby_version = '~> 2.2'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.13'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rubocop', '~> 0.46'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-minitest'
end
