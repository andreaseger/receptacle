# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/test_*.rb']
end

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
  namespace :rubocop do
    desc 'Install Rubocop as pre-commit hook'
    task :install do
      require 'rubocop_runner'
      RubocopRunner.install
    end
  end
rescue LoadError
  p 'rubocop not installed'
end

task default: :test
