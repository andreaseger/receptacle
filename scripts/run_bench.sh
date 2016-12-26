export RBENV_VERSION=ruby-2.3.3
ruby -v
ruby scripts/bench.rb

export RBENV_VERSION=ruby-2.4.0
ruby -v
ruby scripts/bench.rb

export JRUBY_OPTS=''
export RBENV_VERSION=jruby-9.1.6.0
ruby -v
ruby scripts/bench.rb

export JRUBY_OPTS='-Xcompile.invokedynamic=true'
export RBENV_VERSION=jruby-9.1.6.0
ruby -v
ruby scripts/bench.rb
