# An interface to S3, with support for storing files and communicating via
# message queues.
module Online
  class << self
    # The environment in which to run the gem.  Defaults to
    # <code>Rails.env</code> if present, or to <code>'test'</code>
    # otherwise.
    def env
      @env || if defined?(Rails) then Rails.env else 'test' end
    end

    # Set the default environment for running the gem.
    attr_writer :env

    # The prefix to use for bucket names.  May be specified using
    # <code>ENV['ONLINE_BUCKET_PREFIX']</code>.
    def bucket_prefix
      @bucket_prefix || ENV['ONLINE_BUCKET_PREFIX'] or
        raise ArgumentError.new("Please specify ONLINE_BUCKET_PREFIX in your " +
                                "environment")
    end

    # Set the bucket prefix.
    attr_writer :bucket_prefix

    # The directory in which to store mock S3 objects during testing.
    attr_reader :mock_storage_directory
    attr_writer :mock_storage_directory

    # Compute a bucket name for the specified storage type.
    def bucket_name_for(storage_type)
      pieces = [bucket_prefix]

      case storage_type
      when :s3
        pieces << env_and_maybe_user
      when :s3_cdn
        pieces << 'cdn'
        pieces << env_and_maybe_user
      when :queue
        pieces << 'queue'
        case env
        when 'live'
          # Do nothing.
        when 'development'
          pieces << 'staging'
        else
          pieces << env_and_maybe_user
        end
      else
        raise ArgumentError
      end
        
      pieces.join('.')
    end

    # Enable (or disable) mock objects for this library.
    def mock!(mock=true)
      require 'online/test' unless defined?(Online::Test)
      @mocked = mock
      Storage.clear_cached_buckets
    end

    # Return either Online::Storage, or a mock implementation of the same
    # API, depending on whether or not we're currently mocked.
    def storage_class
      if @mocked
        Online::Test::MockStorage
      else
        Online::Storage
      end
    end

    # Return the directory that we'll use to mock the specified bucket.
    # Since we'll be using this directory heavily, we're careful to only
    # return a path if the user has specified
    # <code>mock_storage_directory</code>.
    def mock_storage_directory_for(bucket_name)
      if mock_storage_directory
        "#{mock_storage_directory}/#{bucket_name}/"
      else
        raise ArgumentError.new("No Online.mock_storage_directory specified")
      end
    end

    protected

    # In the development environment, we give each user their own bucket.
    def env_and_maybe_user
      case env
      when 'development', 'test' then "#{env}.#{ENV['USER']}"
      else env
      end
    end
  end
end

require 'online/storage'
require 'online/queue'
