require 'test_helper'
require 'online_storage_tests'

class TestOnlineStorage < Test::Unit::TestCase
  include OnlineStorageTests

  def setup
    Online.mock!(false)
    super
    @cdn = Online.storage_class.new(:s3_cdn)
    @cdn.empty_bucket
  end

  # We'll move this back into OnlineStorageTests once we fix MockStorage to
  # support more than one bucket.
  def test_2_instances
    @s3.write('foo/bar1', 's3')
    @cdn.write('foo/bar2', "cdn")
    @s3.write('foo/bar3', 's3 again')
    assert_equal 2, @s3.keys('foo/').size
    assert_equal 1, @cdn.keys('foo/').size
  end
end
