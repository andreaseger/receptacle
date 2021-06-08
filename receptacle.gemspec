# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "receptacle/version"

Gem::Specification.new do |spec|
  spec.name = "receptacle"
  spec.version = Receptacle::VERSION
  spec.authors = ["Andreas Eger"]
  spec.email = ["dev@eger-andreas.de"]

  spec.summary = "repository pattern"
  spec.description = "provides functionality for the repository or strategy pattern"
  spec.homepage = "https://github.com/andreaseger/receptacle"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 2.4"

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", ">= 1.13", "< 3"
  spec.add_development_dependency "codecov"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-minitest"
  spec.add_development_dependency "guard-rubocop"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "standard"
  spec.add_development_dependency "simplecov", "~> 0.13"
end
