$: << (File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
require 'test_helper'

TinyMongo.configure({:host => 'localhost', :database => 'tinymongo_test'})
TinyMongo.connect

class Dummy < TinyMongo::Model
  mongo_collection :dummies
  mongo_key :foo
  mongo_key :bar
end

class TinyMongoTest < Test::Unit::TestCase
  def setup
    TinyMongo.db['dummies'].drop()
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
    assert_equal({ 'obj1'  => { 'foo' => 'hello', 'bar' => 'world' }, 
                   'obj2'  => { 'foo' => 'love', 'bar' => 'ek' },
                   'hash'  => { 'obj' => { 'foo' => 'hello', 'bar' => 'world' } },
                   'array' => [ { 'foo' => 'hello', 'bar' => 'world' }, { 'foo' => 'love', 'bar' => 'ek' }, 'yay' ],
                   'val'   => 'pete' },
                 TinyMongo::Helper.hashify_models_in_hash(hash))
  end
  
  def test_helper_hashify_models_in_array
    obj1 = Dummy.new(:foo => 'hello', :bar => 'world')
    obj2 = Dummy.new(:foo => 'love', :bar => 'ek')
    array = [ obj1, obj2, { :obj => obj1 }, [obj1, obj2, 'yay'], 'pete' ]
    assert_equal([ { 'foo' => 'hello', 'bar' => 'world' }, 
                   { 'foo' => 'love', 'bar' => 'ek' },
                   { 'obj' => { 'foo' => 'hello', 'bar' => 'world' } },
                   [ { 'foo' => 'hello', 'bar' => 'world' }, { 'foo' => 'love', 'bar' => 'ek' }, 'yay' ],
                   'pete' ],
                 TinyMongo::Helper.hashify_models_in_array(array))
  end
  
  def test_mongo_key
    m = Dummy.new('foo' => 'hello')
    m.bar = 'world'
    
    assert_equal 'hello', m.foo
    assert_equal 'world', m.bar
  end
  
  def test_save_new
    hash = {'foo' => 'hello', 'bar' => 'world'}
    
    obj = Dummy.new(hash) 
    obj.save # save to db
    hash['_id'] = obj._id # add _id to hash
    result = TinyMongo.db['dummies'].find_one({'_id' => obj._id})
    assert_equal TinyMongo::Helper.stringify_keys_in_hash(hash), result # compare
  end
  
  def test_create
    hash = {'foo' => 'hello', 'bar' => 'world'}
    
    obj = Dummy.create(hash) # save to db
    hash['_id'] = obj._id # add _id to hash
    
    result = TinyMongo.db['dummies'].find_one({'_id' => obj._id})
    assert_equal TinyMongo::Helper.stringify_keys_in_hash(hash), result, result # compare
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
    found = Dummy.find()
    assert_equal [], found
  end
    
  def test_find_all_one
    obj = Dummy.create('foo' => 'hello') 
    found = Dummy.find()
    assert_equal [obj], found
  end
  
  def test_find_all_many
    obj = Dummy.create('foo' => 'hello') 
    obj2 = Dummy.create('foo' => 'hello') 
    found = Dummy.find()
    assert_equal [obj, obj2], found
  end
  
  def test_find_among_many
    obj = Dummy.create('foo' => 'hello') 
    obj2 = Dummy.create('foo' => 'hello') 
    obj3 = Dummy.create('foo' => 'bye') 
    found1 = Dummy.find({'foo' => 'hello'})
    found2 = Dummy.find({'foo' => 'bye'})
    assert_equal [obj, obj2], found1
    assert_equal [obj3], found2
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
    assert_equal({'_id' => obj._id, 'foo' => 'hello'}, obj.to_hash)
  end
  
  def test_eq
    obj = Dummy.create('foo' => 'hello')
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
  
end