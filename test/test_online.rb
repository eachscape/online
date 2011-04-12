require 'test_helper'

class TestOnlineStorage < Test::Unit::TestCase
  def setup
    # Save the values we use to compute our configuration.
    @saved_online_bucket_prefix = ENV['ONLINE_BUCKET_PREFIX']
  end

  def teardown
    # Restore the values we use to compute our configuration.
    ENV['ONLINE_BUCKET_PREFIX'] = @saved_online_bucket_prefix
    Online.env = nil
    Online.bucket_prefix = nil
  end

  def test_env_should_default_to_test_if_no_rails_env
    assert_equal 'test', Online.env
  end

  #def test_env_should_default_to_rails_env_if_present

  def test_env_should_be_settable
    Online.env = 'development'
    assert_equal 'development', Online.env
  end

  def test_bucket_prefix_should_default_to_com_eachscape
    ENV['ONLINE_BUCKET_PREFIX'] = nil
    assert_equal 'com.eachscape', Online.bucket_prefix
  end

  def test_bucket_prefix_should_honor_environment_variable
    ENV['ONLINE_BUCKET_PREFIX'] = 'com.example'
    assert_equal 'com.example', Online.bucket_prefix
  end

  def test_bucket_prefix_should_be_settable
    Online.bucket_prefix = 'com.example.two'
    assert_equal 'com.example.two', Online.bucket_prefix
  end
end
