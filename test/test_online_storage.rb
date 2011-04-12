require 'test_helper'

class TestOnlineStorage < Test::Unit::TestCase
  # This tests REAL online storage, not MockOnlineStorage
  def setup
    @s3 = Online::Storage.new(:s3)
    @s3.empty_bucket
    @cdn = Online::Storage.new(:s3_cdn)
    @cdn.empty_bucket
  end

  def test_bad_type
    assert_raises(ArgumentError) {Online::Storage.new(:foo)}
  end

  def test_create
    @s3.write('foo', 'This is the contents')
    assert_equal 1, @s3.keys('').size
  end
  
  def test_pattern
    @s3.write('foo/1.png', 'This is the contents')
    @s3.write('foo/2.jpg', 'This is the contents')
    @s3.write('foo/3.png', 'This is the contents')
    @s3.write('bar/5.png', 'This is the contents')
    assert_equal 2, @s3.keys('foo/', {:pattern => '*.png'}).size
  end

  def test_max
    @s3.write('foo/4.png', 'This is the contents')
    @s3.write('foo/3.png', 'This is the contents')
    @s3.write('foo/2.jpg', 'This is the contents')
    @s3.write('foo/1.png', 'This is the contents')
    keys = @s3.keys('foo/', {:max => 3})
    assert_equal ['foo/1.png', 'foo/2.jpg', 'foo/3.png'], keys
  end

  def test_before
    @s3.write('foo/4.png', 'This is the contents')
    @s3.write('foo/3.png', 'This is the contents')
    @s3.write('foo/2.jpg', 'This is the contents')
    @s3.write('foo/1.png', 'This is the contents')
    keys = @s3.keys('foo/', {:before => 'foo/3.'})
    assert_equal ['foo/1.png', 'foo/2.jpg'], keys
  end

  def test_delete
    @s3.write('foo1', 'This is the contents')
    @s3.write('foo2', 'This is the contents')
    @s3.objs('foo2').first.delete
    assert_equal 1, @s3.keys('').size
  end
  
  def test_2_instances
    @s3.write('foo/bar1', 's3')
    @cdn.write('foo/bar2', "cdn")
    @s3.write('foo/bar3', 's3 again')
    assert_equal 2, @s3.keys('foo/').size
    assert_equal 1, @cdn.keys('foo/').size
  end
end
