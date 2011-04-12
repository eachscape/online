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

    # The prefix to use for bucket names.  Defaults to
    # <code>'com.eachscape'</code>, but may be overridden using
    # <code>ENV['ONLINE_BUCKET_PREFIX']</code>.
    def bucket_prefix
      @bucket_prefix || ENV['ONLINE_BUCKET_PREFIX'] || 'com.eachscape'
    end

    # Set the bucket prefix.
    attr_writer :bucket_prefix

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
          pieces << env
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

    protected

    # In the development environment, we give each user their own bucket.
    def env_and_maybe_user
      case env
      when 'development' then "#{env}.#{ENV['USER']}"
      else env
      end
    end
  end
end

require 'online/storage'
