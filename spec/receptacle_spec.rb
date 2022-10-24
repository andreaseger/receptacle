# frozen_string_literal: true

require "spec_helper"

describe Receptacle::Repo do
  context "with a strategy" do
    let(:repository) do
      test_wrappers = wrappers
      test_strategy = strategy

      Class.new do
        include Receptacle::Repo

        mediate :find
        mediate :delete

        wrappers(test_wrappers)
        strategy(test_strategy)
      end
    end

    let(:strategy) do
      Class.new do
        def find(id, unscoped: true) # rubocop:disable Lint/UnusedMethodArgument
          id + 50
        end

        def delete(id:) # rubocop:disable Lint/UnusedMethodArgument
          "deleted"
        end
      end
    end

    let(:strategy_instance) { strategy.new }

    before do
      allow(strategy_instance).to receive(:find)
        .and_call_original
      allow(strategy_instance).to receive(:delete)
        .and_call_original
      allow(strategy).to receive(:new)
        .and_return(strategy_instance)
    end

    context "without wrappers being defined" do
      let(:repository) do
        test_strategy = strategy

        Class.new do
          include Receptacle::Repo

          mediate :find
          mediate :delete

          strategy(test_strategy)
        end
      end

      it "calls the method on the strategy" do
        expect(repository.find(10, unscoped: false)).to eql(60)

        expect(strategy_instance).to have_received(:find)
          .with(10, unscoped: false)
      end
    end

    context "with two wrappers that modify input and output of the find method" do
      let(:wrappers) do
        [
          add5_wrapper,
          add10_flip_unscoped_and_multiply_result_wrapper
        ]
      end
      let(:add5_wrapper) do
        Class.new do
          def find(id, unscoped: true)
            yield(id + 5, unscoped: unscoped)
          end
        end
      end
      let(:add10_flip_unscoped_and_multiply_result_wrapper) do
        Class.new do
          def find(id, unscoped: true)
            yield(id + 10, unscoped: !unscoped) * 100
          end
        end
      end
      let(:add5_wrapper_instance) { add5_wrapper.new }
      let(:add10_flip_unscoped_and_multiply_result_wrapper_instance) do
        add10_flip_unscoped_and_multiply_result_wrapper.new
      end

      before do
        allow(add5_wrapper).to receive(:new)
          .and_return(add5_wrapper_instance)
        allow(add5_wrapper_instance).to receive(:find)
          .and_call_original

        allow(add10_flip_unscoped_and_multiply_result_wrapper).to receive(:new)
          .and_return(add10_flip_unscoped_and_multiply_result_wrapper_instance)
        allow(add10_flip_unscoped_and_multiply_result_wrapper_instance).to receive(:find)
          .and_call_original
      end

      describe ".find" do
        it "calls the first wrapper with the input arguments" do
          repository.find(5, unscoped: true)

          expect(add5_wrapper_instance).to have_received(:find)
            .with(5, unscoped: true)
        end

        it "calls the second wrapper with the output of the first wrapper" do
          repository.find(5)

          expect(add10_flip_unscoped_and_multiply_result_wrapper_instance).to have_received(:find)
            .with(5 + 5, unscoped: true)
        end

        it "calls the strategy with the output of the second wrapper" do
          repository.find(5)

          expect(strategy_instance).to have_received(:find)
            .with(5 + 5 + 10, unscoped: false)
        end

        it "returns correct value for find" do
          expect(repository.find(5, unscoped: true)).to eq((5 + 5 + 10 + 50) * 100)
        end
      end

      describe ".delete" do
        context "when no wrapper implements the delete function" do
          it "calls the strategy only" do
            expect(repository.delete(id: 10)).to eql("deleted")
          end
        end

        context "when only the first wrapper implements the delete function" do
          let(:add5_wrapper) do
            Class.new do
              def delete(id:)
                yield(id: id + 5)
              end
            end
          end

          before do
            allow(add5_wrapper_instance).to receive(:delete)
              .and_call_original
          end

          it "calls the first wrapper with the input arguments" do
            repository.delete(id: 5)

            expect(add5_wrapper_instance).to have_received(:delete)
              .with(id: 5)
          end

          it "calls the strategy with the output of the first wrapper" do
            repository.delete(id: 5)

            expect(strategy_instance).to have_received(:delete)
              .with(id: 5 + 5)
          end

          it "returns correct value for delete" do
            expect(repository.delete(id: 5)).to eq("deleted")
          end
        end

        context "when only the second wrapper implements the delete function" do
          let(:add10_flip_unscoped_and_multiply_result_wrapper) do
            Class.new do
              def delete(id:)
                yield(id: id + 10)
              end
            end
          end

          before do
            allow(add10_flip_unscoped_and_multiply_result_wrapper_instance).to receive(:delete)
              .and_call_original
          end

          it "calls the second wrapper with the input arguments" do
            repository.delete(id: 5)

            expect(add10_flip_unscoped_and_multiply_result_wrapper_instance).to have_received(:delete)
              .with(id: 5)
          end

          it "calls the strategy with the output of the second wrapper" do
            repository.delete(id: 5)

            expect(strategy_instance).to have_received(:delete)
              .with(id: 5 + 10)
          end

          it "returns correct value for delete" do
            expect(repository.delete(id: 5)).to eq("deleted")
          end
        end
      end
    end
  end

  context "with a repository that has no strategy" do
    let(:repository) do
      Class.new do
        include Receptacle::Repo

        mediate :find
      end
    end

    it "throws an error when trying to use the repository" do
      expect { repository.find }.to raise_error(Receptacle::Errors::NotConfigured)
    end
  end
end
