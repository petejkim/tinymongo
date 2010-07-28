module TinyMongo
  module Helper
    class << self
      def deep_copy_hash(hash)
        new_hash = {}
        hash.each_pair do |key, obj|
          new_hash[key] = if(obj.instance_of? Hash)
            deep_copy_hash(obj)
          elsif(obj.instance_of? Array)
            deep_copy_array(obj)
          else
            begin 
              obj.dup
            rescue
              obj
            end
          end
        end
        new_hash
      end

      def deep_copy_array(array)
        new_array = []
        array.each do |obj|
          new_array << if(obj.instance_of? Hash)
            deep_copy_hash(obj)
          elsif(obj.instance_of? Array)
            deep_copy_array(obj)
          else
            begin 
              obj.dup
            rescue
              obj
            end
          end
        end
        new_array
      end
      
      def stringify_keys_in_hash(hash)
        new_hash = {}
        hash.each_pair { |key, value| new_hash[key.to_s] = value }
        new_hash['_id'] = bson_object_id(new_hash['_id']) if(new_hash['_id'])
        new_hash
      end

      def symbolify_keys_in_hash(hash)
        new_hash = {}
        hash.each_pair { |key, value| new_hash[key.to_sym] = value }
        new_hash[:_id] = bson_object_id(new_hash[:_id]) if(new_hash[:_id])
        new_hash
      end
      
      def hashify_models_in(obj)
        if(obj.instance_of? Hash)
          hashify_models_in_hash(obj)
        elsif(obj.instance_of? Array)
          hashify_models_in_array(obj)
        elsif(obj.kind_of? TinyMongo::Model)
          obj.to_hash
        else
          obj
        end
      end
      
      def hashify_models_in_array(array)
        new_array = array.map { |value| hashify_models_in(value) }
      end
      
      def hashify_models_in_hash(hash)
        new_hash = {}
        hash.each_pair do |key,value|
          key_s = key.to_s
          if(key_s == '_id')
            new_hash[key_s] = bson_object_id(value)
          else
            new_hash[key_s] = hashify_models_in(value)
          end
        end
        new_hash
      end
      
      def bson_object_id(id)
        if(id.instance_of? BSON::ObjectID)
          id
        elsif(id.instance_of? String)
          BSON::ObjectID(id)
        else
          BSON::ObjectID(id.to_s)
        end
      end
    end
  end
end