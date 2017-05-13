# frozen_string_literal: true

module Receptacle
  module TestSupport
    # with_strategy
    #
    # provides helpful method to toggle strategies during testing
    #
    # can be used in rspec like this
    #
    #    require 'receptacle/test_support'y
    #    RSpec.configure do |c|
    #      c.include Receptacle::TestSupport
    #    end
    #
    #    RSpec.describe(UserRepository) do
    #      around do |example|
    #        with_strategy(strategy){example.run}
    #      end
    #      let(:strategy) { UserRepository::Strategy::MySQL }
    #      ...
    #    end
    #
    # or similar with minitest
    #
    #    require 'receptacle/test_support'
    #    class UserRepositoryTest < Minitest::Test
    #      def described_class
    #        UserRepository
    #      end
    #      def repo_exists(strategy)
    #        with_strategy(strategy) do
    #          assert described_class.exists(id: 5)
    #        end
    #      end
    #      def test_mysql
    #        repo_exists(UserRepository::Strategy::MySQL)
    #      end
    #      def test_fake
    #        repo_exists(UserRepository::Strategy::Fake)
    #      end
    #    end
    def with_strategy(strategy, repo = described_class)
      original_strategy = repo.strategy
      repo.strategy strategy
      yield
    ensure
      repo.strategy original_strategy
    end

    # ensure_method_delegators
    #
    # When using something like `allow(SomeRepo).to receive(:find)` (where find
    # is a mediated method) before the method was called the first time Rspec
    # would stub the method with the wrong arity of 0 when also using jruby.
    # This seems to be caused by the lazily defined methods. Simply calling the
    # following method in a before hook when method stubbing is need solves this
    # issue. As it's a problem which only affects mocking libraries it's
    # currently not planned to change this behavior.
    #
    def ensure_method_delegators(repo)
      Receptacle::Registration.repositories[repo].methods.each do |method_name|
        repo.__build_method(method_name)
      end
    end
  end
end
