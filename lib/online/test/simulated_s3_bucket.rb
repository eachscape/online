module Online::Test
  class SimulatedS3Bucket
    attr_reader :global_state

    def initialize(name)
      raise ArgumentError unless name  # We don't support nil name
      @name = name
      @global_state = SimulatedS3GlobalState.new
      @global_state.set_current_bucket_to(name)
      @path = @global_state.current_bucket_path
    end

    def delete(options)
      raise Exception, "foo" unless @path # can't seem to raise AWS::S3::NoSuchBucket
      begin
        if options[:force]
          FileUtils.rm_rf(@path)
        else
          FileUtils.rm_dir(@path)
        end
      rescue Exception => e
        raise AWS::S3::BucketNotEmpty.new('The bucket you tried to delete is not empty', nil) if e.is_a?(Errno::ENOTEMPTY)
        raise e
      end
    end
  
    def empty
      FileUtils.rm_rf(@path)
      FileUtils.mkdir(@path)
    end

    def objects(options)
      prefix = options[:prefix]
      marker = options[:marker]
      max_keys = options[:max_keys] || 1.megabyte 
      prefix = prefix[0..-2] if prefix && prefix[-1, 1] == '/'

      #  NOTE: File system will only work at path boundary for prefixes...
      return [] unless File.exist?("#{@path}#{prefix}")
      result = []
      `find '#{@path}#{prefix}' -name '*' -type f`.split("\n").sort.each do |line|
        key = line[@path.size, 99999]
        result << global_state.find(key, nil) if marker.nil? || (key > marker)
        break if result.size >= max_keys
      end
      result
    end
  end  
end
