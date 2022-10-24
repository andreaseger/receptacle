#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/inline"
gemfile true do
  source "https://rubygems.org"
  gem "receptacle", "~> 2"
  gem "mongo"
end
require "irb"

# a simple struct to act as business entity
User = Struct.new(:id, :name)

# we have a global mongo connection which can be easily reused
module Connection
  class Mongo
    include Singleton

    def initialize
      ::Mongo::Logger.logger.level = Logger::INFO
      @client = ::Mongo::Client.new(["127.0.0.1:27017"], database: "receptacle")
      client[:users].delete_many # empty collection
    end
    attr_reader :client

    def self.client
      instance.client
    end
  end
end

# define our Repository
module Repository
  module User
    include Receptacle::Repo
    mediate :find
    mediate :create
    mediate :clear
  end
end

# some strategies
module Repository
  module User
    module Strategy
      class Mongo
        def find(id:)
          mongo_to_model(collection.find(_id: id).first)
        rescue StandardError
          nil
        end

        def create(name:)
          ret = collection.insert_one(name: name)
          find(id: ret.inserted_id)
        end

        def clear
          collection.delete_many
        end

        private

        def mongo_to_model(doc)
          ::User.new(doc["_id"], doc["name"])
        end

        def collection
          Connection::Mongo.client[:users]
        end
      end

      # in memory is using a simple class instance variable as internal storage

      class InMemory
        class << self; attr_accessor :store end
        @store = {}
        def find(id:)
          store[id]
        end

        def create(name:)
          id = BSON::ObjectId.new
          store[id] = ::User.new(id, name)
        end

        def clear
          self.class.store = {}
        end

        private

        def store
          self.class.store
        end
      end
    end
  end
end

# configure the repository and use it
Repository::User.strategy Repository::User::Strategy::InMemory

user = Repository::User.create(name: "foo")
print "created user: "
p user
print "find user by id: "
p Repository::User.find(id: user.id)

# switching to mongo and we see it's using a different store but keeps the same interface
Repository::User.strategy Repository::User::Strategy::Mongo

print "search same user in other strategy: "
p Repository::User.find(id: user.id)
#-> nil

user = Repository::User.create(name: "foo mongo")
print "create new user: "
p user
print "find new user by id: "
p Repository::User.find(id: user.id)
