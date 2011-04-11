require 'aws/s3'

require 'simulated_s3_bucket'
require 'simulated_s3_object'

class MockOnlineStorage < OnlineStorage
  
  def initialize(store_type)
    raise ArgumentError unless [:s3, :s3_cdn, :queue].include?(store_type)
    @store_type = store_type
    pieces = ['com.eachscape']
    if store_type == :queue
      pieces << 'queue'
      pieces << 'test' if Rails.env.test?  # Only for unit tests, otherwise everyone uses the same queue
    else
      pieces << 'cdn' if store_type == :s3_cdn
      pieces << OnlineStorage.env_extension
    end
    @bucket_name = pieces.join('.')

    SimulatedS3Object.set_current_bucket_to @bucket_name
    @bucket = SimulatedS3Bucket.find(@bucket_name)                                                    
  end
  

  def public_path(key)
    # get the path without checking to find the object or even see if it's public!
    # We took this approach because sometimes we need to know the URL before the
    # object exists.
    SimulatedS3Object.public_path(key)
  end
  
  def url_for(key, options = {})
    SimulatedS3Object.public_path(key)
  end

  def write(key, object_or_stream, options = {})
    mime_type = options.delete(:mime_type) || 'text/plain'
    options.merge!(:content_type => mime_type)
    response = SimulatedS3Object.store(key, object_or_stream, @bucket_name, options)
  end

  def empty_bucket
    if @bucket_name =~ /^com\.eachscape(\.cdn)?\.(development|test)/ || 
            @bucket_name == 'com.eachscape.queue.test' 
      @bucket.empty
    else
      raise 'Can only delete bucket in test/development environment ' + @bucket_name 
    end
  end
  
  def exist?(key)
    begin
      response = SimulatedS3Object.find(key, @bucket_name)
      return true
    rescue AWS::S3::NoSuchKey => e
      return false
    end
  end

  def find(key)
    SimulatedS3Object.find(key, @bucket_name)
  end

end