module TinyMongo
  class Error < StandardError
  end
  
  class NotConfiguredError < Error
    def initialize
      super('Please do TinyMongo.configure() before attempting to connect!')
    end
  end
  
  class NotConnectedError < Error
    def initialize
      super('Not connected to MongoDB. Please connect using TinyMongo.connect()!')
    end
  end
  
  class ModifierOperationError < Error
    def initialize
      super('Modifier operations are not allowed on objects that are not yet saved!')
    end
  end
  
  class DeserializationError < Error
    def initialize(class_name)
      super("Unable to deserialize hash into #{class_name}!")
    end
  end
end