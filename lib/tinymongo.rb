require 'mongo'

module TinyMongo
  class << self
    def configure(config)
      config = Helper.stringify_keys_in_hash(config)
    
      @host = config['host'] || 'localhost'
      @port = config['port']
      @options = config['options'] || {}
      @database = config['database'] || 'mongo'
      @username = config['username']
      @password = config['password']
      @configured = true
    end
  
    def db
      @db
    end

    def connect
      raise NotConfiguredError unless @configured
      
      if defined?(PhusionPassenger) && @connection
        PhusionPassenger.on_event(:starting_worker_process) do |forked|
          @connection.connect_to_master if forked
        end
      end
        
      if(@connection.nil?)
        @connection = Mongo::Connection.new(@host, @port, @options)
        @db = @connection.db(@database)

        if(@username && @password) 
          auth = db.authenticate(@username, @password)
          return nil unless(auth)
        end
      end
      
      @connected = true
    end
    
    def connected?
      @connected ? true : false
    end
  end
end

require 'tinymongo/errors'
require 'tinymongo/helper'
require 'tinymongo/model'
