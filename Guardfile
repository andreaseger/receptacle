# frozen_string_literal: true
# A sample Guardfile
# More info at https://github.com/guard/guard#readme

## Uncomment and set this to only include directories you want to watch
# directories %w(app lib config test spec features) \
#  .select{|d| Dir.exists?(d) ? d : UI.warning("Directory #{d} does not exist")}

## Note: if you are using the `directories` clause above and you are not
## watching the project directory ('.'), then you will want to move
## the Guardfile to a watched dir and symlink it back, e.g.
#
#  $ mkdir config
#  $ mv Guardfile config/
#  $ ln -s config/Guardfile .
#
# and, you'll have to watch "config/Guardfile" instead of "Guardfile"
group :red_green_refactor, halt_on_fail: true do
  guard :minitest do
    # with Minitest::Unit
    watch(%r{^test/(.*)\/?test_(.*)\.rb$})
    # watch(%r{^lib/(.*/)?([^/]+)\.rb$})     { |m| "test/#{m[1]}test_#{m[2]}.rb" }
    watch(%r{^lib/(.*/)?([^/]+)\.rb$})     { 'test' }
    watch(%r{^test/test_helper\.rb$})      { 'test' }
    watch(%r{^test/fixture\.rb$}) { 'test' }
  end
  guard :rubocop, all_on_start: false, cli: ['--auto-correct'] do
    watch(/.+\.rb$/)
    watch(%r{(?:.+/)?\.rubocop\.yml%}) { |m| File.dirname(m[0]) }
  end
end
