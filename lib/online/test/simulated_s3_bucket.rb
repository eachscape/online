module Online::Test
  class SimulatedS3Bucket
    def initialize(name, path)
      @name = name
      @path = path
    end

    def self.find(name = nil)
      raise ArgumentError unless name  # We don't support nil name
      self.new(name, SimulatedS3Object.current_bucket_path)
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
        result << SimulatedS3Object.find(key, nil) if marker.nil? || (key > marker)
        break if result.size >= max_keys
      end
      result
    end
  end  
end
