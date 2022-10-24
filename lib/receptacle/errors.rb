# frozen_string_literal: true

module Receptacle
  module Errors
    class NotConfigured < StandardError
      attr_reader :repo

      def initialize(repo:)
        @repo = repo
        super("Missing Configuration for repository: <#{repo}>")
      end
    end
  end
end
