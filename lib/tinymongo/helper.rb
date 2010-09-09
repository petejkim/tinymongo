module TinyMongo
  module Helper
    class << self
      def constantize(class_name)
        return unless class_name.instance_of? String
        class_name.split('::').inject(Object) { |mod, klass| mod.const_get(klass) }
      end
      
      def deep_copy(obj)
        if(obj.kind_of? Hash)
          Hash[obj.map { |k,v| [k.to_s, deep_copy(v)] }]
        elsif(obj.kind_of? Array)
          obj.map { |o| deep_copy(o)}
        else
          begin
            obj.dup
          rescue
            obj
          end
        end
      end
        
      def stringify_keys_in_hash(hash)
        new_hash = Hash[hash.map { |k,v| [k.to_s, v] }]
        new_hash['_id'] = bson_object_id(new_hash['_id']) if(new_hash['_id'])
        new_hash
      end

      def symbolify_keys_in_hash(hash)
        new_hash = Hash[hash.map { |k,v| [k.to_sym, v] }]
        new_hash[:_id] = bson_object_id(new_hash[:_id]) if(new_hash[:_id])
        new_hash
      end
      
      def deserialize_hashes_in(obj)
        if(obj.kind_of? Hash)
          new_hash = Hash[obj.map { |k,v| [k.to_s, deserialize_hashes_in(v)] }]
          class_name = new_hash['_tinymongo_model_class_name']
          if(class_name)
            begin
              klass = constantize(new_hash['_tinymongo_model_class_name'])
              if(klass.new.kind_of? TinyMongo::Model)
                deserialized_obj = klass.new(new_hash)
              else
                raise
              end
            rescue
              raise DeserializationError, class_name
            end
            deserialized_obj
          else
            new_hash
          end
        elsif(obj.kind_of? Array)
          obj.map { |o| deserialize_hashes_in(o) }
        else
          obj
        end
      end
      
      def hashify_models_in(obj)
        if(obj.kind_of? Hash)
          Hash[obj.map do |k,v| 
            key = k.to_s
            (key == '_id') ? [key, bson_object_id(v)] : [key, hashify_models_in(v)]
          end]
        elsif(obj.kind_of? Array)
          obj.map { |o| hashify_models_in(o) }
        elsif(obj.kind_of? TinyMongo::Model)
          hashify_models_in(obj.to_hash)
        else
          obj
        end
      end

      def bson_object_id(id)
        if(id.instance_of? BSON::ObjectId)
          id
        elsif(id.instance_of? String)
          BSON::ObjectId(id)
        else
          BSON::ObjectId(id.to_s)
        end
      end
    end
  end
end