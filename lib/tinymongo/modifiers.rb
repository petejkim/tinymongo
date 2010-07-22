module TinyMongo
  module Modifiers
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
  
    def add_to_set(hash={})
      do_modifier_operation_and_reload('$addToSet', hash)
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
    
    protected
    def do_modifier_operation_and_reload(operator, hash)
      raise ModifierOperationError unless self._id
      collection.update({ '_id' => self._id }, { operator => Helper.hashify_models_in_hash(hash) })
      reload
    end
  end
end