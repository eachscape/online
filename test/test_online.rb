require 'test_helper'

class TestOnline < Test::Unit::TestCase
  def setup
    # Save the values we use to compute our configuration.
    @saved_online_bucket_prefix = ENV['ONLINE_BUCKET_PREFIX']
    @saved_mock_storage_directory = Online.mock_storage_directory

    # Set the values we use to compute our configuration to a known state.
    #ENV['ONLINE_BUCKET_PREFIX'] = nil -Leave with value from environment.
    Online.env = nil
    Online.bucket_prefix = nil

    # Turn off mocking.
    Online.mock!(false)
  end

  def teardown
    # Restore the values we use to compute our configuration.
    ENV['ONLINE_BUCKET_PREFIX'] = @saved_online_bucket_prefix
    Online.mock_storage_directory = @saved_mock_storage_directory
    Online.env = nil
    Online.bucket_prefix = nil

    # Turn off mocking.
    Online.mock!(false)
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
    assert_raises(ArgumentError) { Online.bucket_prefix }
  end

  def test_bucket_prefix_should_honor_environment_variable
    ENV['ONLINE_BUCKET_PREFIX'] = 'com.example'
    assert_equal 'com.example', Online.bucket_prefix
  end

  def test_bucket_prefix_should_be_settable
    Online.bucket_prefix = 'com.example.two'
    assert_equal 'com.example.two', Online.bucket_prefix
  end

  def test_bucket_name_for_should_raise_an_error_if_storage_type_is_unknown
    assert_raises(ArgumentError) { Online.bucket_name_for(:unknown) }
  end

  def test_bucket_name_for_should_build_appropriate_bucket_names
    examples = [{
       :for => :s3,
       :env => 'production',
       :bucket_prefix => 'com.example.three',
       :expected => 'com.example.three.production'
     }, {
       :for => :s3,
       :env => 'live',
       :bucket_prefix => 'com.example.three',
       :expected => 'com.example.three.live'
     }, {
       :for => :s3,
       :env => 'development',
       :bucket_prefix => 'com.example',
       :expected => "com.example.development.#{ENV['USER']}"
     }, {
       :for => :s3,
       :env => 'test',
       :bucket_prefix => 'com.example',
       :expected => "com.example.test.#{ENV['USER']}"
     }, {
       :for => :s3_cdn,
       :env => 'live',
       :bucket_prefix => 'com.example',
       :expected => 'com.example.cdn.live'
     }, {
       :for => :s3_cdn,
       :env => 'production',
       :bucket_prefix => 'com.example',
       :expected => 'com.example.cdn.production'
     }, {
       :for => :s3_cdn,
       :env => 'development',
       :bucket_prefix => 'com.example',
       :expected => "com.example.cdn.development.#{ENV['USER']}"
     }, {
       :for => :queue,
       :env => 'live',
       :bucket_prefix => 'com.example',
       :expected => 'com.example.queue'
     }, {
       :for => :queue,
       :env => 'development',
       :bucket_prefix => 'com.example',
       :expected => 'com.example.queue.staging' # Yes, staging.
     }, {
       :for => :queue,
       :env => 'staging',
       :bucket_prefix => 'com.example',
       :expected => 'com.example.queue.staging'
     }]

    for example in examples
      Online.env = example[:env]
      Online.bucket_prefix = example[:bucket_prefix]
      assert_equal example[:expected], Online.bucket_name_for(example[:for])
    end
  end

  def test_storage_class_should_return_storage_if_not_mocked
    Online.mock!(false)
    assert_equal Online::Storage, Online.storage_class
  end

  def test_storage_class_should_return_mock_storage_if_mocked
    Online.mock!
    assert_equal Online::Test::MockStorage, Online.storage_class
  end

  def test_mock_storage_directory_for_should_return_a_directory
    Online.mock_storage_directory = "/tmp/foo"
    assert_equal("/tmp/foo/bucket/",
                 Online.mock_storage_directory_for('bucket'))
  end

  def test_mock_storage_directory_for_should_fail_if_no_mock_storage_directory
    Online.mock_storage_directory = nil
    assert_raises(ArgumentError) { Online.mock_storage_directory_for('bucket') }
  end
end
