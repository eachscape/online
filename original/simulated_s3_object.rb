require 'aws/s3'
require 'simulated_s3_bucket'

class SimulatedS3Object
  include AWS::S3

  def initialize(path)
    @path = path
  end
  
  def self.public_path(k)
    "file://localhost/#{current_bucket_path}/#{k}"
  end
  
  def about
    return {} unless File.exist?(@path)
    {'last-modified' => File.mtime(@path).utc.rfc822.sub(/ -0000$/, ' GMT'),
     'content-type' => 'text/plain',
     'etag' => "Fake etag #{File.mtime(@path).utc.to_i}",
     'content-length' => File.size(@path).to_s,
     'last-modified' => Time.now.utc.rfc822.sub(/ -0000$/, ' GMT')}
  end
  
  def self.find(key, bucket)
    file_path = "#{bucket_path_to(bucket)}#{key}"
    raise AWS::S3::NoSuchKey.new("No such key '#{key}'", nil) unless File.exist?(file_path)
    SimulatedS3Object.new(file_path)
  end

  def rename(key)
    begin
      target = SimulatedS3Object.find(key)
    rescue Exception => e
      raise e unless e.is_a?(AWS::S3::NoSuchKey)
    end
    FileUtils.makedirs(File.dirname("#{@@bucket_path}#{key}"))
    File.rename storage_path, "#{@@bucket_path}#{key}"
    true
  end

  def self.bucket_path_to(name)
      unless name
        return @@bucket_path if @@bucket_path
        raise AWS::S3::NoSuchBucket.new('The specified bucket does not exist', nil)
      end
      return "#{Rails.configuration.storage_root}/#{name}/"
      FileUtils.makedirs(bucket_path)
      bucket_path
    end

  def self.set_current_bucket_to(name)
    @@bucket_path = "#{Rails.configuration.storage_root}/#{name}/"
    FileUtils.makedirs(@@bucket_path)
  end

  def self.current_bucket_path
    raise AWS::S3::NoSuchBucket.new('The specified bucket does not exist', nil) unless @@bucket_path
    @@bucket_path
  end

  def etag
    self.about['etag']
  end
  
  def delete
    raise AWS::S3::NoSuchBucket.new('The specified bucket does not exist', nil) unless @@bucket_path
    file_path = "#{@@bucket_path}#{key}"
    File.delete(@path)
    true
  end

  def self.store(key, data, bucket_name, options)
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
  
  def key
    @path[@@bucket_path.size, 99999]
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
end
