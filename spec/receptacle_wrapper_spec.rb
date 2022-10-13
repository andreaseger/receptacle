# frozen_string_literal: true

require "spec_helper"
require "spec/test_repositories"

describe Receptacle::Repo do
  let(:repository) do
    test_wrappers = wrappers
    test_strategy = strategy
    Class.new do
      include Receptacle::Repo

      mediate :find

      wrappers(test_wrappers)
      strategy(test_strategy)
    end
  end
  let(:strategy) do
    Class.new do
      def find(number, unscoped: true)
        puts "number: #{number} unscoped: #{unscoped.inspect}"
        number
      end
    end 
  end

  context 'with two wrappers that modify input and output' do
    let(:wrappers) do
      [
        add5_wrapper,
        add10_flip_unscoped_and_multiply_result_wrapper
      ]
    end
    let(:add5_wrapper) do
      Class.new do
        def find(number, unscoped:)
          yield(number + 5, unscoped: unscoped)
        end
      end
    end
    let(:add10_flip_unscoped_and_multiply_result_wrapper) do
      Class.new do
        def find(number, unscoped:)
          yield(number + 10, unscoped: !unscoped) * 100
        end
      end
    end

    before do
      allow_any_instance_of(strategy).to receive(:find)
        .with(20, unscoped: false)
        .and_call_original
    end
  
    it "returns correct value for find" do
      expect(repository.find(5, unscoped: true)).to eq(2000)
    end
  end
end

