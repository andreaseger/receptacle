module Receptacle
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

  module TestSupport
    def with_strategy(strategy, repo = described_class, &block)
      original_strategy = repo.strategy
      repo.strategy strategy
      yield
      repo.strategy original_strategy
    end
  end
end
