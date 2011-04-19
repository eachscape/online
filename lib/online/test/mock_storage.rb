require 'online/test/simulated_s3_global_state'
require 'online/test/simulated_s3_object'
require 'online/test/simulated_s3_bucket'

module Online::Test

  # A fake version of Online::Storage, for use by unit tests that don't
  # want to connect to the network.
  class MockStorage < Online::Storage
  
    def initialize(store_type)
      @store_type = store_type
      @bucket_name = Online.bucket_name_for(store_type)
      @bucket = SimulatedS3Bucket.new(@bucket_name)
    end

    def public_path(key)
      # get the path without checking to find the object or even see if
      # it's public!  We took this approach because sometimes we need to
      # know the URL before the object exists.
      @bucket.global_state.public_path(key)
    end
  
    def url_for(key, options = {})
      @bucket.global_state.public_path(key)
    end

    def write(key, object_or_stream, options = {})
      mime_type = options.delete(:mime_type) || 'text/plain'
      options.merge!(:content_type => mime_type)
      response = @bucket.global_state.store(key, object_or_stream, @bucket_name, options)
    end

    def empty_bucket
      if @bucket_name =~ /\.(development|test)\.#{Regexp.quote(ENV['USER'])}$/
        @bucket.empty
      else
        raise 'Can only delete bucket in test/development environment ' + @bucket_name 
      end
    end
  
    def exist?(key)
      begin
        response = @bucket.global_state.find(key, @bucket_name)
        return true
      rescue AWS::S3::NoSuchKey => e
        return false
      end
    end

    def find(key)
      @bucket.global_state.find(key, @bucket_name)
    end
  end
end
