require 'aws/s3'

module Online
  # An S3-based storage interface.
  class Storage
    include AWS::S3
  
    MAX_AT_A_TIME = 800 # S3 limits us to 1000 at a time; we're playing it safe... see not in objs()

    attr_reader :bucket_name
  
    def initialize(store_type)
      @store_type = store_type
      @bucket_name = Online.bucket_name_for(store_type)

      Online::Storage.retryable do
        @@connection = AWS::S3::Base.establish_connection!(:access_key_id => ENV['AWS_ACCESS_KEY_ID'], 
                                                           :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'],
                                                           :use_ssl => true)
                                                       
        S3Object.set_current_bucket_to @bucket_name                                                         
  
        begin
          @bucket = Bucket.find(@bucket_name)
        rescue NoSuchBucket => e
          Bucket.create(@bucket_name) 
          @bucket = Bucket.find(@bucket_name)
        end
      end
    end
  
    # Everyone can use the same instances, so it's not quite a singleton, but it's pretty close
    # This is better than having instances all over the place, and is faster, too, when it comes
    # running remotely because there are fewer instances to create. It was really slow in development
    # environmen before making this change

    def self.default
      Online::Storage.retryable do 
        @@s3_instance ||= Rails.env.test? ? MockOnlineStorage.new(:s3) : Online::Storage.new(:s3)
      end
      @@s3_instance
    end

    def self.cdn
      Online::Storage.retryable do 
        @@cdn_instance ||= Rails.env.test? ? MockOnlineStorage.new(:s3_cdn) : Online::Storage.new(:s3_cdn)
      end
      @@cdn_instance
    end

    def self.queue
      Online::Storage.retryable do 
        # No matter what, this uses REAL online storage
        @@queue_instance ||= Online::Storage.new(:queue)
      end
      @@queue_instance
    end

    def public_path(key)
      # get the path without checking to find the object or even see if it's public!
      # We took this approach because sometimes we need to know the URL before the
      # object exists.
      "http://#{@bucket_name}.s3.amazonaws.com/#{key}"
    end
  
    def url_for(key, options = {})
      # gets the url for the object using S3Object.url_for()
      Online::Storage.retryable {S3Object.url_for(key, @bucket_name, options)}
    end

    def write(key, object_or_stream, options = {})
      mime_type = options.delete(:mime_type) || 'text/plain'
      options.merge!(:content_type => mime_type)
      response = Online::Storage.retryable {S3Object.store(key, object_or_stream, @bucket_name, options)}
    end
  
    def delete_object(storage_path)   
      S3Object.delete(storage_path, @bucket_name)
    end
  
    def empty_bucket
      if @bucket_name =~ /\.(development|test)\.#{Regexp.quote(ENV['USER'])}$/
        @bucket.delete_all
      else
        raise 'Can only delete bucket in test/development environment ' + @bucket_name 
      end
    end

    def exist?(key)
      begin
        response = Online::Storage.retryable {S3Object.find(key, @bucket_name)}
        return true
      rescue AWS::S3::NoSuchKey => e
        return false
      end
    end

    def objs(prefix, options={})
      # Supported options
      #   :max   controls how many records come back
      result = []
      set = []
      pattern = options[:pattern]
      opts = {:prefix => prefix, :max_keys => MAX_AT_A_TIME} # S3-related limit
      begin
        set = @bucket.objects(opts)
        set.each do |obj|
          return result if options[:before] && obj.key >= options[:before]
          if pattern
            result << obj if File.fnmatch(pattern, File.basename(obj.key)) 
          else
            result << obj
          end
          return result if options[:max] && (result.size == options[:max])
        end
        break if set.size < MAX_AT_A_TIME # This optimization will cause breakage if S3 ever reduces the limit below our limit.
        # Currently this limit is 1,000 at S3, but we've pegged it at 800 for safety.
        opts.merge!(:marker => set.last.key) unless set.empty?
      end until set.empty?
      return result
    end

    def keys(prefix, options={})
      self.objs(prefix, options).map{|o| o.key}
    end
  
    def find(key)
      Online::Storage.retryable {S3Object.find(key, @bucket_name)}
    end

    def self.env_extension
      ext = [Rails.env]
      ext << "#{ENV['USER'].downcase}" if Rails.env == 'development'
      ext.join('.')
    end

    def self.retryable(options = {}, &block)
      opts = {:tries => 4, :on => Exception}.merge(options)

      retries = opts[:tries]
      begin
        return yield
      rescue opts[:on]
        retry if (retries -= 1) > 0
      end
      yield
    end
  end
end
