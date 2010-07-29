module TinyMongo
  class Model
    class << self
      def mongo_key(*args)
        default = nil
        @_tinymongo_defaults = {} if @_tinymongo_defaults.nil?
        
        args.each do |arg|
          default = arg[:default] || arg['default'] if(arg.kind_of? Hash)
        end
        
        args.each do |arg|
          if([Symbol, String].include? arg.class)
            key_name_s = arg.to_s
            key_name_sym = arg.to_sym

            define_method(key_name_sym) { instance_variable_get(:@_tinymongo_hash)[key_name_s] }
            define_method("#{key_name_s}=") { |val| instance_variable_get(:@_tinymongo_hash)[key_name_s] = val }
            
            @_tinymongo_defaults[key_name_s] = default if default
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
      
      def full_name
        "#{db.name}.#{collection.name}"
      end
      
      def get_full_name
        full_name
      end
      
      def getFullName
        full_name
      end
      
      def find(query={}, fields=nil, limit=nil, skip=nil)
        query = Helper.hashify_models_in(query)
        fields = Helper.hashify_models_in(fields)
        
        add_tinymongo_model_class_name_key_to_fields(fields)
        Cursor.new(collection.find(query, {:fields => fields, :limit => limit, :skip => skip}), self)
      end
      
      def find_one(query={}, fields=nil)
        return nil unless query
        
        if([BSON::ObjectID, String].include? query.class)
          query = {'_id' => Helper.bson_object_id(query)}
        else
          query = Helper.hashify_models_in(query)
          fields = Helper.hashify_models_in(fields)
        end
        
        add_tinymongo_model_class_name_key_to_fields(fields)
        hash = collection.find_one(query, {:fields => fields})
        hash ? Helper.deserialize_hashes_in(hash) : nil
      end

      def findOne(*args)
        find_one(*args)
      end

      def create(hash={})
        obj = self.new(hash)
        obj.save
      end
      
      def delete(id)
        collection.remove({ '_id' => Helper.bson_object_id(id)})
      end

      def destroy(*args)
        delete(*args)
      end
      
      def remove(*args)
        delete(*args)
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
      
      def ensure_index(keys, options={})
        if(keys.kind_of? Hash)
          keys = keys.map { |k,v| [k.to_s, convert_ascending_descending_2d(v)]}
        elsif(keys.kind_of? Array)
          keys = keys.map { |o| (o.kind_of? Array) ? [o[0].to_s, convert_ascending_descending_2d(o[1])] : nil }.compact
        end
        options = Helper.symbolify_keys_in_hash(options)
        collection.create_index(keys, options)
      end
      
      def ensureIndex(*args)
        ensure_index(*args)
      end
      
      def drop_index(obj)
        if(obj.instance_of? String)
          index = obj
        elsif(obj.kind_of? Hash)
          index = get_index_name(obj)
        elsif(obj.kind_of? Array)
          index = get_index_name(Hash[obj])
        else
          return
        end
        
        collection.drop_index(index)
      end
      
      def dropIndex(*args)
        drop_index(*args)
      end
      
      def drop_indexes
        collection.drop_indexes
      end
      
      def dropIndexes
        drop_indexes
      end
      
      def get_indexes
        collection.index_information.map { |k,v| v }
      end
      
      def getIndexes
        get_indexes
      end
      
      def distinct(key, query=nil)
        if(query.kind_of? Hash)
          query = Helper.hashify_models_in(query)
        end
        collection.distinct(key, query)
      end
    end
    
    def initialize(hash={})
      @_tinymongo_hash = {}
      defaults = self.class.instance_variable_get(:@_tinymongo_defaults)
      defaults = self.class.instance_variable_set(:@_tinymongo_defaults, {}) if(defaults.nil?)
      hash = Helper.deep_copy(defaults).merge(Helper.stringify_keys_in_hash(hash || {}))
      hash.each_pair { |key, value| set_using_setter(key, value) }
      set_tinymongo_model_class_name_in_hash(@_tinymongo_hash)
      self
    end

    def _id
      @_tinymongo_hash['_id']
    end
    
    def _id=(val)
      @_tinymongo_hash['_id'] = Helper.bson_object_id(val)
    end
    
    def ==(another)
      (self.instance_variable_get(:@_tinymongo_hash) == another.instance_variable_get(:@_tinymongo_hash)) &&
      (self.kind_of? TinyMongo::Model) && (another.kind_of? TinyMongo::Model)
    end
    
    def db
      self.db
    end
  
    def collection
      self.class.collection
    end
    
    def to_hash
      hash = @_tinymongo_hash.dup
    end
    
    def to_param
      @_tinymongo_hash['_id'].to_s
    end
    
    def reload
      if(@_tinymongo_hash['_id'])
        obj = collection.find_one({ '_id' => @_tinymongo_hash['_id'] })
        @_tinymongo_hash = Hash[obj.map { |k,v| [k.to_s, Helper.deserialize_hashes_in(v)] }] if(obj)
      end
    end

    def save
      if(@_tinymongo_hash['_id'].nil?) # new 
        oid = collection.save(Helper.hashify_models_in(@_tinymongo_hash))
        if(oid)
          @_tinymongo_hash.delete(:_id)
          @_tinymongo_hash['_id'] = oid
        end
      else # update
        collection.update({ '_id' => @_tinymongo_hash['_id'] }, Helper.hashify_models_in(@_tinymongo_hash), :upsert => true)
        reload
      end
      return self
    end
  
    def update_attribute(key, value)
      set_using_setter(key, value)
      save
    end
  
    def update_attributes(hash={})
      hash.each_pair { |key, value| set_using_setter(key, value) }
      save
    end
    
    def delete
      if(@_tinymongo_hash['_id'])
        collection.remove({ '_id' => @_tinymongo_hash['_id'] })
      end
    end
  
    def destroy
      delete
    end
      
    def inc(hash={})
      do_modifier_operation_and_reload('$inc', hash)
    end

    def set(hash={})
      do_modifier_operation_and_reload('$set', hash)
    end

    def unset(hash={})
      do_modifier_operation_and_reload('$unset', hash)
    end

    def push(hash={})
      do_modifier_operation_and_reload('$push', hash)
    end
    
    def push_all(hash={})
      do_modifier_operation_and_reload('$pushAll', hash)
    end
    
    def pushAll(*args)
      push_all(*args)
    end

    def add_to_set(hash={})
      do_modifier_operation_and_reload('$addToSet', hash)
    end
    
    def addToSet(*args)
      add_to_set(*args)
    end

    def pop(hash={})
      do_modifier_operation_and_reload('$pop', hash)
    end

    def pull(hash={})
      do_modifier_operation_and_reload('$pull', hash)
    end

    def pull_all(hash={})
      do_modifier_operation_and_reload('$pullAll', hash)
    end
    
    def pullAll(*args)
      pull_all(*args)
    end
  
    protected
    def do_modifier_operation_and_reload(operator, hash)
      raise ModifierOperationError unless @_tinymongo_hash['_id']
      collection.update({ '_id' => @_tinymongo_hash['_id'] }, { operator => Helper.hashify_models_in(hash) })
      reload
    end
    
    def set_tinymongo_model_class_name_in_hash(hash)
      hash['_tinymongo_model_class_name'] = self.class.to_s
      hash
    end
    
    def self.add_tinymongo_model_class_name_key_to_fields(fields)
      if(fields.kind_of? Hash)
        fields['_tinymongo_model_class_name'] = 1
      elsif(fields.kind_of? Array)
        fields << '_tinymongo_model_class_name'
      end
      fields
    end
    
    def set_using_setter(key, value)
      setter = key.to_s + '='
      self.send(setter, value) if(self.respond_to? setter)
    end
    
    def self.convert_ascending_descending_2d(val)
      case(val.to_s)
      when 'ascending', 'asc', '1', Mongo::ASCENDING.to_s
        Mongo::ASCENDING
      when 'descending', 'desc', '-1', Mongo::DESCENDING.to_s
        Mongo::DESCENDING
      when '2d', Mongo::GEO2D.to_s
        Mongo::GEO2D
      else
        val
      end
    end
    
    def self.convert_ascending_descending_to_numeric(val)
      case(val.to_s)
      when 'ascending', 'asc', '1', Mongo::ASCENDING.to_s
        1
      when 'descending', 'desc', '-1', Mongo::DESCENDING.to_s
        -1
      else
        val
      end
    end
    
    def self.get_index_name(hash)
      name = ''
      hash.each_pair do |k,v|
        name += '_' if(name.length > 0)
        name += k.to_s + '_'
        v = convert_ascending_descending_to_numeric(v)
        name += v.to_s if(v.kind_of? Integer)
      end
      name
    end
  end
end
