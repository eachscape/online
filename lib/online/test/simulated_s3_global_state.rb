module Online::Test
  # This class contains some state that used to be contained in global
  # variables in SimulatedS3Object.  It has been pulled out and placed in
  # instances of this class with very few further changes.  Eventually,
  # this code should probably be absorbed into SimulatedS3Bucket.
  class SimulatedS3GlobalState
    def public_path(k)
      "file://localhost/#{current_bucket_path}/#{k}"
    end
  
    def find(key, bucket)
      file_path = "#{bucket_path_to(bucket)}#{key}"
      raise AWS::S3::NoSuchKey.new("No such key '#{key}' at #{file_path}", nil) unless File.exist?(file_path)
      SimulatedS3Object.new(self, file_path)
    end

    def bucket_path_to(name)
      unless name
        return @bucket_path if @bucket_path
        raise AWS::S3::NoSuchBucket.new('The specified bucket does not exist', nil)
      end
      return Online.mock_storage_directory_for(name)
      FileUtils.makedirs(bucket_path)
      bucket_path
    end

    def set_current_bucket_to(name)
      @bucket_path = Online.mock_storage_directory_for(name)
      FileUtils.makedirs(@bucket_path)
    end

    def current_bucket_path
      raise AWS::S3::NoSuchBucket.new('The specified bucket does not exist', nil) unless @bucket_path
      @bucket_path
    end

    def store(key, data, bucket_name, options)
      bucket_path = self.bucket_path_to(bucket_name)
      FileUtils.makedirs(File.dirname("#{bucket_path}#{key}"))
      File.open("#{bucket_path}#{key}", 'w') do |f|
        if data.class.ancestors.include?(IO)
          until data.eof?
            f.write data.read(2048)
          end
        else
          File.open("#{bucket_path}#{key}", 'w') {|f| f.write data}
        end
      end
    end    
  end
end
