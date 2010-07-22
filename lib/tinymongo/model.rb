require 'tinymongo/modifiers'

module TinyMongo
  class Model
    class << self
      def mongo_key(*args)
        args.each do |key_name|
          if([Symbol, String].include? key_name.class)
            key_name_s = key_name.to_s
            key_name_sym = key_name.to_sym

            define_method(key_name_sym) do
              instance_variable_get("@_tinymongo_hash")[key_name_s]
            end

            define_method("#{key_name_s}=".to_sym) do |val|
              instance_variable_get("@_tinymongo_hash")[key_name_s] = val
            end
          end
        end
      end
      
      def mongo_collection(name)
        @_tinymongo_collection_name = name.to_s
      end
      
      def db
        TinyMongo.db
      end

      def collection
        if @_tinymongo_collection_name
          TinyMongo.db[@_tinymongo_collection_name]
        elsif(defined?(Rails))
          TinyMongo.db[self.to_s.gsub('/','_').tableize]
        else
          TinyMongo.db[self.to_s]
        end
      end
      
      def find(*args)
        return [] if((args.size > 0) && (args.compact.size == 0))
        
        new_args = args.map {|arg| Helper.hashify_models_in(arg) }
        cursor = collection.find(*new_args)
        
        if(cursor)
          hashes = cursor.to_a
          objs = hashes.map { |hash| self.new(hash) }
        end
        
        cursor ? objs : []
      end

      def find_one(*args)
        if((args.size > 0) && (args.compact.size == 0))
          return nil
        elsif((args.size == 1) && ([BSON::ObjectID, String].include? args[0].class))
          hash = collection.find_one({'_id' => Helper.bson_object_id(args[0])})
        else
          new_args = args.map {|arg| Helper.hashify_models_in(arg) }
          hash = collection.find_one(*new_args)
        end
        hash ? self.new(hash) : nil
      end

      def create(hash={})
        obj = self.new(hash)
        obj.save
      end
      
      def delete(id)
        collection.remove({ '_id' => Helper.bson_object_id(id)})
      end

      def drop
        collection.drop
      end

      def delete_all
        drop
      end
      
      def destroy_all
        drop
      end
      
      def count
        collection.count
      end
    end
    
    def initialize(hash={})
      @_tinymongo_hash = Helper.stringify_keys_in_hash(hash)
    end

    def _id
      @_tinymongo_hash['_id']
    end
    
    def _id=(val)
      @_tinymongo_hash['_id'] = Helper.bson_object_id(val)
    end
    
    def ==(another)
      self.to_hash == another.to_hash
    end
    
    def db
      self.db
    end
  
    def collection
      self.class.collection
    end
    
    def to_hash
      @_tinymongo_hash.dup
    end
    
    def reload
      if(self._id)
        obj = collection.find_one({ '_id' => self._id })
        @_tinymongo_hash = Helper.stringify_keys_in_hash(obj) if(obj)
      end
    end

    def save
      if(self._id.nil?) # new 
        oid = collection.save(@_tinymongo_hash)
        if(oid)
          @_tinymongo_hash.delete(:_id)
          self._id = oid
        end
      else # update
        collection.update({ '_id' => self._id }, @_tinymongo_hash, :upsert => true)
        reload
      end
      return self
    end
  
    def update_attribute(name, value)
      send(name.to_s + '=', value)
      save
    end
  
    def update_attributes(hash)
      hash.each_pair { |key, value| send(key.to_s + '=', value) }
      save
    end
  
    def delete
      if(self._id)
        collection.remove({ '_id' => self._id })
      end
    end
  
    def destroy
      delete
    end
  
    def destroy(id)
      delete(id)
    end
    
    include Modifiers
  end
end
