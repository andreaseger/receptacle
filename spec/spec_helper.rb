# frozen_string_literal: true

require "bundler"

$LOAD_PATH.unshift(Bundler.root)

require "receptacle"
require "pry"

[
  "spec/support/**/*.rb"
].each do |pattern|
  Dir[File.join(pattern)].sort.each { |file| require file }
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
  config.expose_dsl_globally = true
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
