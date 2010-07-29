module TinyMongo
  class Cursor
    include Mongo::Conversions
    include Enumerable
    
    # instance attributes in Mongo::Cursor
    
    def initialize(cursor, model_class)
      @_tinymongo_cursor = cursor
      @_tinymongo_model_class = model_class
    end
    
    def mongo_cursor
      @_tinymongo_cursor
    end
    
    def count
      @_tinymongo_cursor.count
    end
    
    def size
      num = (count - skip)
      num = (num > 0) ? (((num > limit) && limit != 0) ? limit : num) : 0
    end
    
    def each
      num_returned = 0
      while(has_next? && (@_tinymongo_cursor.instance_variable_get(:@limit) <= 0 ||
        num_returned < @_tinymongo_cursor.instance_variable_get(:@limit)))
        yield next!
        num_returned += 1
      end
    end
    
    def forEach(*args)
      each(*args)
    end
    
    def explain
      @_tinymongo_cursor.explain
    end
    
    def has_next?
      @_tinymongo_cursor.has_next?
    end
    
    def hasNext
      has_next?
    end
    
    def limit(number_to_return=nil)
      call_and_wrap_retval_in_tinymongo_cursor(:limit, [number_to_return])
    end
    
    def next!
      doc = @_tinymongo_cursor.next_document
      Helper.deserialize_hashes_in(doc)
    end
    
    def next_document
      next!
    end
    
    def nextDocument
      next!
    end
    
    def skip(number_to_skip=nil)
      call_and_wrap_retval_in_tinymongo_cursor(:skip, [number_to_skip])
    end
    
    def sort(key_or_list, direction=nil)
      if(key_or_list.kind_of? Hash)
        key_or_list = key_or_list.map { |k, v| [k.to_s, convert_ascending_descending(v)] }
      elsif(key_or_list.kind_of? Array)
        key_or_list = key_or_list.map { |o| (o.kind_of? Array) ? [o[0].to_s, convert_ascending_descending(o[1])] : nil }.compact
      end
        
      call_and_wrap_retval_in_tinymongo_cursor(:sort, [key_or_list, direction])
    end
    
    def to_a
      return [] if @_tinymongo_cursor.nil?
      
      hashes = @_tinymongo_cursor.to_a
      hashes.map { |hash| Helper.deserialize_hashes_in(hash) }
    end
    
    protected
    def call_and_wrap_retval_in_tinymongo_cursor(method_name, args)
      result = @_tinymongo_cursor.send(method_name, *args)
      if(result.kind_of? Mongo::Cursor)
        @_tinymongo_cursor = result
        self
      else
        result
      end
    end
    
    def convert_ascending_descending(val)
      case(val.to_s)
      when 'ascending', 'asc', '1', Mongo::ASCENDING.to_s
        Mongo::ASCENDING
      when 'descending', 'desc', '-1', Mongo::DESCENDING.to_s
        Mongo::DESCENDING
      else
        val
      end
    end
  end
end