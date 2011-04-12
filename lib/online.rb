require 'aws/s3'

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
      raise ArgumentError unless [:s3].include?(storage_type)
      [bucket_prefix, env].join('.')
    end
  end
end
