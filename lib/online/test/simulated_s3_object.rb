module Online::Test
  class SimulatedS3Object
    include AWS::S3

    def initialize(path)
      @path = path
    end

    def about
      return {} unless File.exist?(@path)
      {'last-modified' => File.mtime(@path).utc.rfc822.sub(/ -0000$/, ' GMT'),
        'content-type' => 'text/plain',
        'etag' => "Fake etag #{File.mtime(@path).utc.to_i}",
        'content-length' => File.size(@path).to_s,
        'last-modified' => Time.now.utc.rfc822.sub(/ -0000$/, ' GMT')}
    end

    def rename(key)
      begin
        target = SimulatedS3Object.find(key)
      rescue Exception => e
        raise e unless e.is_a?(AWS::S3::NoSuchKey)
      end
      FileUtils.makedirs(File.dirname("#{bucket_path}#{key}"))
      File.rename storage_path, "#{bucket_path}#{key}"
      true
    end

    def etag
      self.about['etag']
    end
  
    def delete
      raise AWS::S3::NoSuchBucket.new('The specified bucket does not exist', nil) unless bucket_path
      file_path = "#{bucket_path}#{key}"
      File.delete(@path)
      true
    end
  
    def key
      @path[bucket_path.size, 99999]
    end

    def value
      File.open(@path, 'r') {|f| return f.read}
    end

    def stream
      File.open(@path, 'r')
    end
  
    def delete
      File.delete(@path)
    end

    def bucket_path
      SimulatedS3GlobalState.current_bucket_path
    end
  end
end
