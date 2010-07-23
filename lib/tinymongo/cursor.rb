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
    
    def batch_size
      @_tinymongo_cursor.batch_size
    end
    
    def collection
      @_tinymongo_cursor.collection
    end
    
    def fields 
      @_tinymongo_cursor.fields
    end
    
    def full_collection_name
      @_tinymongo_cursor.full_collection_name
    end
    
    def hint
      @_tinymongo_cursor.hint
    end 
    
    def order
      @_tinymongo_cursor.order
    end
    
    def selector
      @_tinymongo_cursor.selector
    end
    
    def snapshot
      @_tinymongo_cursor.snapshot
    end
    
    def timeout
      @_tinymongo_cursor.timeout
    end
    
    # instance methods in Mongo::Cursor
    
    def close
      @_tinymongo_cursor.close
    end
    
    def closed?
      @_tinymongo_cursor.closed?
    end
    
    def count
      @_tinymongo_cursor.count
    end
    
    def each
      num_returned = 0
      while(has_next? && (@_tinymongo_cursor.instance_variable_get(:@limit) <= 0 ||
        num_returned < @_tinymongo_cursor.instance_variable_get(:@limit)))
        yield next_document
        num_returned += 1
      end
    end
    
    def explain
      @_tinymongo_cursor.explain
    end
    
    def has_next?
      @_tinymongo_cursor.has_next?
    end
    
    def limit(*args)
      call_and_wrap_retval_in_tinymongo_cursor(:limit, args)
    end
    
    def next_document
      doc = @_tinymongo_cursor.next_document
      @_tinymongo_model_class.new(doc)
    end
    
    def query_options_hash
      @_tinymongo_cursor.query_options_hash
    end
    
    def query_opts
      @_tinymongo_cursor.query_opts
    end
    
    def skip(*args)
      call_and_wrap_retval_in_tinymongo_cursor(:skip, args)
    end
    
    def sort(*args)
      if(args.length > 0 && (args[0].instance_of? Hash))
        sort_array = []
        
        args[0].each_pair do |key, value|
          sort_array << [key, convert_ascending_descending_to_numeric(value)]
        end
        
        args[0] = sort_array
      end
        
      call_and_wrap_retval_in_tinymongo_cursor(:sort, args)
    end
    
    def to_a
      return [] if @_tinymongo_cursor.nil?
      
      hashes = @_tinymongo_cursor.to_a
      hashes.map { |hash| @_tinymongo_model_class.new(hash) }
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
    
    def convert_ascending_descending_to_numeric(val)
      case(val)
      when 'ascending', 'asc', 1
        'ascending'
      when 'descending', 'desc', -1
        'descending'
      end
    end
  end
end