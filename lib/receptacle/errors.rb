# frozen_string_literal: true
module Receptacle
  module Errors
    class NotConfigured < StandardError
      attr_reader :repo
      def initialize(repo:)
        @repo = repo
        super(repo.to_s)
      end
    end
    class ReservedMethodName < StandardError; end
  end
end
