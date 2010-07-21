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
        raise 'Not connected to MongoDB. Please connect using TinyMongo.connect().' unless TinyMongo.connected?
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
        new_args = []
        args.each do |arg|
          new_args << Helper.hashify_models_in(arg)
        end
        collection.find(*new_args)
      end

      def find_one(*args)
        if([BSON::ObjectID, String].include? args[0].class)
          obj = collection.find_one({'_id' => Helper.bson_object_id(args[0])})
        else
          obj = collection.find_one(*args)
        end
        obj ? self.new(obj) : nil
      end

      def create(hash)
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
    
    def db
      self.db
    end
  
    def collection
      self.class.collection
    end
    
    def to_hash
      @_tinymongo_hash.clone
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
  
    def inc(hash)
      hash.each_pair do |key, value|
        key = key.to_s
        
        if(@_tinymongo_hash[key] && (@_tinymongo_hash[key].kind_of? Numeric))
          send(key + '=', (send(key) + value))
        else
          send(key + '=', value)
        end
      end
    
      if(self._id)
        collection.update({ '_id' => self._id }, { '$inc' => Helper.hashify_models_in_hash(hash) })
        reload
      end
    end
  
    def set(hash)
      hash.each_pair { |key, value| send(key.to_s + '=', value) }
    
      if(self._id)
        collection.update({ '_id' => self._id }, { '$set' => Helper.hashify_models_in_hash(hash) })
        reload
      end
    end
  
    def unset(hash)
      hash.each_key do |key| 
        @_tinymongo_hash.delete(key.to_s)
      end
    
      if(self._id)
        collection.update({ '_id' => self._id }, { '$unset' => Helper.hashify_models_in_hash(hash) })
        reload
      end
    end
  
    def push(hash)
      hash.each_pair do |key, value|
        key = key.to_s
        
        if(@_tinymongo_hash[key] && (@_tinymongo_hash[key].instance_of? Array))
          send(key) << value
        else
          send(key + '=', value)
        end
      end
    
      if(self._id)
        collection.update({ '_id' => self._id }, { '$push' => Helper.hashify_models_in_hash(hash) })
        reload
      end
    end
  
    def push_all(hash)
      hash.each_pair do |key, value|
        key = key.to_s
        
        if(@_tinymongo_hash[key] && (@_tinymongo_hash[key].instance_of? Array))
          value.each { |v| send(key) << value }
        else
          send(key + '=', value)
        end
      end

      if(self._id)
        collection.update({ '_id' => self._id }, { '$pushAll' => Helper.hashify_models_in_hash(hash) })
        reload
      end
    end
  
    def add_to_set(hash)
      hash.each_pair do |key, value|
        key = key.to_s
        
        if(!(@_tinymongo_hash[key].include? value) && (@_tinymongo_hash[key].instance_of? Array))
          send(key) << value
        end
      end
    
      if(self._id)
        collection.update({ '_id' => self._id }, { '$addToSet' => Helper.hashify_models_in_hash(hash) })
        reload
      end
    end
  
    def pop(hash)
      hash.each_pair do |key, value|
        key = key.to_s

        if(@_tinymongo_hash[key] && (@_tinymongo_hash[key].instance_of? Array))
          if(value == 1)
            send(key).pop
          elsif(value == -1)
            send(key).shift
          end
        end
      end
    
      if(self._id)
        collection.update({ '_id' => self._id }, { '$pop' => Helper.hashify_models_in_hash(hash) })
        reload
      end
    end
  
    def pull(hash)
      hash.each_pair do |key, value|
        key = key.to_s
        if(@_tinymongo_hash[key] && (@_tinymongo_hash[key].instance_of? Array))
          send(key).delete_if { |v| v == value }
        end
      end
    
      if(self._id)
        collection.update({ '_id' => self._id }, { '$pull' => Helper.hashify_models_in_hash(hash) })
        reload
      end
    end
  
    def pull_all(hash)
      hash.each_pair do |key, value|
        key = key.to_s
        if(@_tinymongo_hash[key] && (@_tinymongo_hash[key].instance_of? Array))
          value.each do |v|
            send(key).delete_if { |w| w == v }
          end
        end
      end
    
      if(self._id)
        collection.update({ '_id' => self._id }, { '$pullAll' => Helper.hashify_models_in_hash(hash) })
        reload
      end
    end
  end
end
