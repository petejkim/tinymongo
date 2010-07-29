$: << (File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
require 'test_helper'

TinyMongo.configure({:host => 'localhost', :database => 'tinymongo_test'})
TinyMongo.connect

class Dummy < TinyMongo::Model
  mongo_collection :dummies
  mongo_key :foo
  mongo_key :bar
end

class DummyTwo < TinyMongo::Model
  mongo_key :foo, :bar
end

class DummyDefault < TinyMongo::Model
  mongo_key :foo, :default => 'hello'
  mongo_key :bar, :default => 'world'
end

class TinyMongoTest < Test::Unit::TestCase
  def setup
    TinyMongo.db['dummies'].drop
  end
  
  def test_helper_stringify_keys_in_hash
    hash = {:foo => 'hello', :bar => 'world'}
    assert_equal({'foo' => 'hello', 'bar' => 'world'}, TinyMongo::Helper.stringify_keys_in_hash(hash))
  end

  def test_helper_symbolify_keys_in_hash
    hash = {'foo' => 'hello', 'bar' => 'world'}
    assert_equal({:foo => 'hello', :bar => 'world'}, TinyMongo::Helper.symbolify_keys_in_hash(hash))
  end
  
  def test_helper_hashify_models_in_hash
    obj1 = Dummy.new(:foo => 'hello', :bar => 'world')
    obj2 = Dummy.new(:foo => 'love', :bar => 'ek')
    hash = { :obj1 => obj1, :obj2 => obj2, :hash => { :obj => obj1 }, :array => [obj1, obj2, 'yay'], :val => 'pete' }
    obj1_hash = { 'foo' => 'hello', 'bar' => 'world', '_tinymongo_model_class_name' => 'Dummy' }
    obj2_hash = { 'foo' => 'love', 'bar' => 'ek', '_tinymongo_model_class_name' => 'Dummy' }
    
    assert_equal({ 'obj1'  => obj1_hash, 
                   'obj2'  => obj2_hash,
                   'hash'  => { 'obj' => obj1_hash },
                   'array' => [ obj1_hash, obj2_hash, 'yay' ],
                   'val'   => 'pete' },
                 TinyMongo::Helper.hashify_models_in(hash))
  end
  
  def test_helper_hashify_models_in_array
    obj1 = Dummy.new(:foo => 'hello', :bar => 'world')
    obj2 = Dummy.new(:foo => 'love', :bar => 'ek')
    array = [ obj1, obj2, { :obj => obj1 }, [obj1, obj2, 'yay'], 'pete' ]
    obj1_hash = { 'foo' => 'hello', 'bar' => 'world', '_tinymongo_model_class_name' => 'Dummy' }
    obj2_hash = { 'foo' => 'love', 'bar' => 'ek', '_tinymongo_model_class_name' => 'Dummy' }
    
    assert_equal([ obj1_hash,
                   obj2_hash,
                   { 'obj' => obj1_hash },
                   [ obj1_hash, obj2_hash, 'yay' ],
                   'pete' ],
                 TinyMongo::Helper.hashify_models_in(array))
  end
  
  def test_mongo_key
    m = Dummy.new('foo' => 'hello')
    m.bar = 'world'
    
    assert_equal 'hello', m.foo
    assert_equal 'world', m.bar
  end
  
  def test_mongo_two_keys_in_one_line
    m = DummyTwo.new('foo' => 'hello')
    m.bar = 'world'
    
    assert_equal 'hello', m.foo
    assert_equal 'world', m.bar
  end
  
  def test_mongo_key_with_default_value
    m = DummyDefault.new
    
    assert_equal 'hello', m.foo
    assert_equal 'world', m.bar
  end
  
  def test_mongo_key_override_default_value
    m = DummyDefault.new(:foo => 'world', :bar => 'hello')
    
    assert_equal 'world', m.foo
    assert_equal 'hello', m.bar
  end
  
  def test_save_new
    hash = {'foo' => 'hello', 'bar' => 'world'}
    
    obj = Dummy.new(hash) 
    obj.save # save to db
    hash['_id'] = obj._id # add _id to hash
    hash['_tinymongo_model_class_name'] = 'Dummy'
    result = TinyMongo.db['dummies'].find_one({'_id' => obj._id})
    assert_equal TinyMongo::Helper.stringify_keys_in_hash(hash), result # compare
  end
  
  def test_create
    hash = {'foo' => 'hello', 'bar' => 'world'}
    
    obj = Dummy.create(hash) # save to db
    hash['_id'] = obj._id # add _id to hash
    hash['_tinymongo_model_class_name'] = 'Dummy'
    
    result = TinyMongo.db['dummies'].find_one({'_id' => obj._id})
    assert_equal TinyMongo::Helper.stringify_keys_in_hash(hash), result, result # compare
  end

  def test_create_ignore_undefined_keys
    obj = Dummy.create({'foo' => 'hello', 'bar' => 'world', 'fubar' => 'snafu'}) # save to db
    
    result = TinyMongo.db['dummies'].find_one({'_id' => obj._id})
    assert_equal TinyMongo::Helper.stringify_keys_in_hash({'foo' => 'hello', 'bar' => 'world', '_id' => obj._id, '_tinymongo_model_class_name' => 'Dummy'}), result, result # compare
  end

  def test_save_update
    obj = Dummy.create('foo' => 'hello') 
    obj.foo = 'bye'
    obj.save
    
    result = TinyMongo.db['dummies'].find_one({'_id' => obj._id})
    assert_equal 'bye', result['foo']
  end
  
  def test_update_attribute
    obj = Dummy.create('foo' => 'hello') 
    obj.update_attribute('foo', 'bye')
    
    result = TinyMongo.db['dummies'].find_one({'_id' => obj._id})
    assert_equal 'bye', result['foo']
  end
  
  def test_update_attributes
    obj = Dummy.create('foo' => 'hello', 'bar' => 'world') 
    obj.update_attributes({'foo' => 'world', 'bar' => 'hello'})
    
    result = TinyMongo.db['dummies'].find_one({'_id' => obj._id})
    assert_equal 'world', result['foo']
    assert_equal 'hello', result['bar']
  end
  
  def test_find_nothing
    found = Dummy.find().to_a
    assert_equal [], found
  end
    
  def test_find_all_one
    obj = Dummy.create('foo' => 'hello') 
    found = Dummy.find().to_a
    assert_equal [obj], found
  end
  
  def test_find_all_many
    obj = Dummy.create('foo' => 'hello') 
    obj2 = Dummy.create('foo' => 'hello') 
    found = Dummy.find().to_a
    assert_equal [obj, obj2], found
  end
  
  def test_find_among_many
    obj = Dummy.create('foo' => 'hello') 
    obj2 = Dummy.create('foo' => 'hello') 
    obj3 = Dummy.create('foo' => 'bye') 
    found1 = Dummy.find({'foo' => 'hello'}).to_a
    found2 = Dummy.find({'foo' => 'bye'}).to_a
    assert_equal [obj, obj2], found1
    assert_equal [obj3], found2
  end
  
  def test_find_fields
    Dummy.create('foo' => 'hello', 'bar' => 'world')
    found = Dummy.find({}, {'foo' => 1}).next!
    assert_equal 'hello', found.foo
    assert_equal nil, found.bar
  end
  
  def test_cursor_count
    3.times { Dummy.create }
    cursor = Dummy.find
    assert_equal 3, cursor.count
  end
  
  def test_cursor_limit
    3.times { Dummy.create }
    cursor = Dummy.find.limit(1)
    assert_equal 1, cursor.to_a.size
  end
  
  def test_cursor_limit_count
    3.times { Dummy.create }
    cursor = Dummy.find.limit(2)
    assert_equal 2, cursor.limit
  end
  
  def test_cursor_size
    10.times { Dummy.create }
    cursor = Dummy.find
    assert_equal 10, cursor.size
  end

  def test_cursor_size_skip
    10.times { Dummy.create }
    cursor = Dummy.find.skip(4)
    assert_equal 6, cursor.size
  end

  def test_cursor_size_limit
    10.times { Dummy.create }
    cursor = Dummy.find.limit(5)
    assert_equal 5, cursor.size
  end

  def test_cursor_size_skip_limit
    10.times { Dummy.create }
    cursor = Dummy.find.skip(3).limit(5)
    assert_equal 5, cursor.size
  end

  def test_cursor_size_skip_too_much
    10.times { Dummy.create }
    cursor = Dummy.find.skip(10)
    assert_equal 0, cursor.size
  end

  def test_cursor_size_skip_limit_out_of_bounds
    10.times { Dummy.create }
    cursor = Dummy.find.skip(7).limit(5)
    assert_equal 3, cursor.size
  end

  def test_cursor_each
    Dummy.create('foo' => 1) 
    Dummy.create('foo' => 2) 
    Dummy.create('foo' => 3) 
    
    cursor = Dummy.find
    num = 0
    cursor.each do |x|
      num += x.foo
    end
    
    assert_equal 6, num
  end

  def test_cursor_has_next?
    Dummy.create
    cursor = Dummy.find
    assert_equal true, cursor.has_next?
  end

  def test_cursor_has_next_is_false
    cursor = Dummy.find
    assert_equal false, cursor.has_next?
  end
  
  def test_cursor_next!
    obj = Dummy.create
    cursor = Dummy.find
    assert_equal obj, cursor.next!
  end

  def test_cursor_next_nil
    cursor = Dummy.find
    assert_equal nil, cursor.next!
  end
  
  def test_cursor_skip
    Dummy.create('foo' => 1) 
    Dummy.create('foo' => 2) 
    obj = Dummy.create('foo' => 3) 
    
    cursor = Dummy.find.skip(2)
    assert_equal obj, cursor.next!
  end

  def test_cursor_skip_all
    Dummy.create('foo' => 1) 
    Dummy.create('foo' => 2) 
    obj = Dummy.create('foo' => 3) 
    
    cursor = Dummy.find.skip(3)
    assert_equal nil, cursor.next!
  end
  
  def test_cursor_skip_count
    Dummy.create('foo' => 1) 
    Dummy.create('foo' => 2) 
    obj = Dummy.create('foo' => 3) 
    
    cursor = Dummy.find.skip(2)
    assert_equal 2, cursor.skip
  end

  def test_cursor_to_a
    obj1 = Dummy.create
    obj2 = Dummy.create
    obj3 = Dummy.create

    cursor = Dummy.find
    assert_equal [obj1, obj2, obj3], cursor.to_a
  end

  def test_cursor_to_a_empty
    cursor = Dummy.find
    assert_equal [], cursor.to_a
  end
  
  def test_cursor_sort
    obj1 = Dummy.create('foo' => 3) 
    obj2 = Dummy.create('foo' => 2) 
    obj3 = Dummy.create('foo' => 1) 
    
    cursor = Dummy.find.sort('foo')
    assert_equal [obj3, obj2, obj1], cursor.to_a
  end

  def test_cursor_sort_array
    obj1 = Dummy.create('foo' => 3) 
    obj2 = Dummy.create('foo' => 2) 
    obj3 = Dummy.create('foo' => 1) 
    
    cursor = Dummy.find.sort([['foo', 'ascending']])
    assert_equal [obj3, obj2, obj1], cursor.to_a
  end
  
  def test_cursor_sort_hash
    obj1 = Dummy.create('foo' => 3) 
    obj2 = Dummy.create('foo' => 2) 
    obj3 = Dummy.create('foo' => 1) 
    
    cursor = Dummy.find.sort({'foo' => 1})
    assert_equal [obj3, obj2, obj1], cursor.to_a
  end
  
  def test_find_one
    obj = Dummy.create('foo' => 'hello') 
    found = Dummy.find_one()
    assert_equal obj, found
  end
  
  def test_find_one_nil
    found = Dummy.find_one(nil)
    assert_equal nil, found
  end
  
  def test_find_one_using_id
    obj = Dummy.create('foo' => 'hello') 
    found = Dummy.find_one(obj._id)
    assert_equal obj, found
  end
  
  def test_find_one_using_id_string
    obj = Dummy.create('foo' => 'hello') 
    found = Dummy.find_one(obj._id.to_s)
    assert_equal obj, found
  end

  def test_find_one_using_id_in_hash
    obj = Dummy.create('foo' => 'hello') 
    found = Dummy.find_one({'_id' => obj._id})
    assert_equal obj, found
  end
  
  def test_find_one_using_id_string_in_hash
    obj = Dummy.create('foo' => 'hello') 
    found = Dummy.find_one({'_id' => obj._id.to_s})
    assert_equal obj, found
  end

  def test_find_one_using_hash
    obj = Dummy.create('foo' => 'hello') 
    found = Dummy.find_one({'foo' => 'hello'})
    assert_equal obj, found
  end
  
  def test_to_hash
    obj = Dummy.create('foo' => 'hello')
    assert_equal({'_id' => obj._id, 'foo' => 'hello', '_tinymongo_model_class_name' => 'Dummy'}, obj.to_hash)
  end
  
  def test_to_param
    obj = Dummy.create
    assert_equal obj._id.to_s, obj.to_param
  end
  
  def test_eq
    obj = Dummy.create
    obj2 = Dummy.find_one()
    assert_equal obj, obj2
  end
  
  def test_count
    Dummy.create('foo' => 'hello')
    Dummy.create('foo' => 'hello')
    Dummy.create('foo' => 'hello')
    
    assert_equal 3, Dummy.count
  end
  
  def test_delete
    obj = Dummy.create('foo' => 'hello')
    assert_equal 1, Dummy.count
    obj.delete
    assert_equal 0, Dummy.count
  end
  
  def test_delete_using_id
    obj = Dummy.create('foo' => 'hello')
    assert_equal 1, Dummy.count
    Dummy.delete(obj._id)
    assert_equal 0, Dummy.count
  end
  
  def test_delete_all
    Dummy.create('foo' => 'hello')
    Dummy.create('foo' => 'hello')
    Dummy.create('foo' => 'hello')
    assert_equal 3, Dummy.count
    Dummy.delete_all
    assert_equal 0, Dummy.count
  end
  
  def test_inc
    d = Dummy.create('foo' => 1)
    assert_equal 1, TinyMongo.db['dummies'].find_one()['foo']
    d.inc({'foo' => 1})
    assert_equal 2, TinyMongo.db['dummies'].find_one()['foo']
  end

  def test_set
    d = Dummy.create('foo' => 'hello')
    assert_equal 'hello', TinyMongo.db['dummies'].find_one()['foo']
    d.set({'foo' => 'bye'})
    assert_equal 'bye', TinyMongo.db['dummies'].find_one()['foo']
  end

  def test_unset
    d = Dummy.create('foo' => 'hello')
    assert_equal 'hello', TinyMongo.db['dummies'].find_one()['foo']
    d.unset({'foo' => 1})
    assert_equal nil, TinyMongo.db['dummies'].find_one()['foo']
  end

  def test_push
    d = Dummy.create('foo' => [])
    assert_equal [], TinyMongo.db['dummies'].find_one()['foo']
    d.push({'foo' => 'hello'})
    assert_equal ['hello'], TinyMongo.db['dummies'].find_one()['foo']
  end

  def test_push_all
    d = Dummy.create('foo' => [])
    assert_equal [], TinyMongo.db['dummies'].find_one()['foo']
    d.push_all({'foo' => ['hello','world']})
    assert_equal ['hello', 'world'], TinyMongo.db['dummies'].find_one()['foo']
  end

  def test_add_to_set
    d = Dummy.create('foo' => [1,2,3,4])
    assert_equal [1,2,3,4], TinyMongo.db['dummies'].find_one()['foo']
    d.add_to_set({'foo' => 1})
    assert_equal [1,2,3,4], TinyMongo.db['dummies'].find_one()['foo']
    d.add_to_set({'foo' => 5})
    assert_equal [1,2,3,4,5], TinyMongo.db['dummies'].find_one()['foo']
  end

  def test_pop
    d = Dummy.create('foo' => [1,2,3,4])
    assert_equal [1,2,3,4], TinyMongo.db['dummies'].find_one()['foo']
    d.pop({'foo' => 1})
    assert_equal [1,2,3], TinyMongo.db['dummies'].find_one()['foo']
    d.pop({'foo' => -1})
    assert_equal [2,3], TinyMongo.db['dummies'].find_one()['foo']
  end

  def test_pull
    d = Dummy.create('foo' => [1,1,2,2,2,3])
    assert_equal [1,1,2,2,2,3], TinyMongo.db['dummies'].find_one()['foo']
    d.pull({'foo' => 2})
    assert_equal [1,1,3], TinyMongo.db['dummies'].find_one()['foo']
  end

  def test_pull_all
    d = Dummy.create('foo' => [1,1,2,2,2,3])
    assert_equal [1,1,2,2,2,3], TinyMongo.db['dummies'].find_one()['foo']
    d.pull_all({'foo' => [1,2]})
    assert_equal [3], TinyMongo.db['dummies'].find_one()['foo']
  end
  
  def test_deserialize
    Dummy.create('foo' => 'array', 'bar' => [Dummy.create('foo' => 'hello'), Dummy.create('foo' => 'world')])
    d = Dummy.find_one({'foo' => 'array'})
    assert_equal 'Dummy', d.class.to_s
    assert_equal 'array', d.foo
    assert_equal 'Dummy', d.bar[0].class.to_s
    assert_equal 'hello', d.bar[0].foo
    assert_equal 'Dummy', d.bar[1].class.to_s
    assert_equal 'world', d.bar[1].foo
  end
  
  def test_full_name
    assert_equal 'tinymongo_test.dummies', Dummy.full_name
  end
  
  def test_get_indexes
    Dummy.create
    assert_equal [{'name' => '_id_', 'ns' => 'tinymongo_test.dummies', 'key' => {'_id' => 1}}], Dummy.get_indexes
  end

  def test_ensure_index
    Dummy.create
    assert_equal 'foo_1', Dummy.ensure_index({'foo' => 1})
    assert_equal 'foo_1_bar_-1', Dummy.ensure_index({'foo' => 1, 'bar' => -1})
    assert_equal [{"name" => "_id_", "ns" => "tinymongo_test.dummies", "key" => {"_id" => 1}},
                  {"name" => "foo_1", "ns" => "tinymongo_test.dummies", "key" => {"foo" => 1}}, 
                  {"name" => "foo_1_bar_-1", "ns" => "tinymongo_test.dummies", "key" => {"foo" => 1, "bar" => -1}}],
                  Dummy.get_indexes
  end
  
  def test_drop_index
    Dummy.create
    index_name = Dummy.ensure_index({'foo' => 1})
    assert_equal [{"name" => "_id_", "ns" => "tinymongo_test.dummies", "key" => {"_id" => 1}},
                  {"name" => "foo_1", "ns" => "tinymongo_test.dummies", "key" => {"foo" => 1}}],
                  Dummy.get_indexes
    Dummy.drop_index(index_name)
    assert_equal [{'name' => '_id_', 'ns' => 'tinymongo_test.dummies', 'key' => {'_id' => 1}}], Dummy.get_indexes
  end
  
  def test_drop_index_hash
    Dummy.create
    index_name = Dummy.ensure_index({'foo' => 1, 'bar' => -1})
    Dummy.drop_index({'foo' => 1, 'bar' => -1})
    assert_equal [{'name' => '_id_', 'ns' => 'tinymongo_test.dummies', 'key' => {'_id' => 1}}], Dummy.get_indexes
  end
  
  def test_drop_index_array
    Dummy.create
    index_name = Dummy.ensure_index({'foo' => 1, 'bar' => -1})
    Dummy.drop_index([['foo', 1], ['bar', -1]])
    assert_equal [{'name' => '_id_', 'ns' => 'tinymongo_test.dummies', 'key' => {'_id' => 1}}], Dummy.get_indexes
  end
  
  def test_drop_indexes
    Dummy.create
    Dummy.ensure_index({'foo' => 1})
    Dummy.ensure_index({'bar' => 1})
    Dummy.drop_indexes
    assert_equal [{'name' => '_id_', 'ns' => 'tinymongo_test.dummies', 'key' => {'_id' => 1}}], Dummy.get_indexes
  end
  
  def test_distinct
    Dummy.create('foo' => 'hello', 'bar' => 'hello')
    Dummy.create('foo' => 'hello', 'bar' => 'world')
    Dummy.create('foo' => 'world', 'bar' => 'world')
    Dummy.create('foo' => 'world', 'bar' => 'world')
    assert_equal ['hello','world'], Dummy.distinct('foo')
    assert_equal ['hello'], Dummy.distinct('foo', {'bar' => 'hello'})
    assert_equal ['hello','world'], Dummy.distinct('foo', {'bar' => 'world'})
  end
end