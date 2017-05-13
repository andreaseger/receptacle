#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/inline'

gemfile true do
  source 'https://rubygems.org'
  gem 'receptacle', '../'
  gem 'mongo'
end

User = Struct.new(:id, :name)

# define our Repository
module Repository
  module User
    include Receptacle::Repo
    mediate :find
    mediate :create
  end
end

# we should have a global mongo connection which can be easily reused
module Connection
  class Mongo
    include Singleton

    def initialize
      @client = ::Mongo::Client.new
    end
    attr_reader :client
    def self.client
      instance.client
    end
  end
end

# some strategies
module Repository
  module User
    module Strategy
      class Mongo
        def find(id:)
          mongo_to_model(collection.find(_id: id))
        rescue
          nil
        end

        def create(name:)
          ret = collection.insert_one(name: name)
          find(id: ret['_id']) # TODO: check this
        end

        private

        def mongo_to_model(doc)
          ::User.new(doc['_id'], doc['name'])
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
          store[id] = User.new(id, name)
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

user = Repository::User.create(name: 'foo')
p user
p Repository::User.find(id: user.id)

# switching to mongo and we see it's using a different store but keeps the same interface
Repository::User.strategy Repository::User::Strategy::Mongo

p Repository::User.find(id: user.id)
#-> nil

user = Repository::User.create(name: 'foo')
p user
p Repository::User.find(id: user.id)
