module Online
  class Queue
    # The volume of activity is way too low to support using Amazon's
    # SQS. The queues are distributed and as a result, you can make a
    # request for an item and get nothing back, because it doesn't check
    # the entire queue. If you have a farm of readers, this works just
    # fine.

    # Instead, we'll just use S3 for our queueing mechanism. Only one
    # problem: we want to have a single queue across all environments, but
    # normally our S3 (Online::Storage) class writes to a bucket based on
    # the environment. Instead, we use a special bucket.
  
    def initialize(name)
      # @queue used to be stored in a global variable, but we made it local
      # so that we can turn mocking off and on again.
      @queue = Online::Storage.queue
      @name = name
    end
  
    def purge_all_queues # Only for testing!
      if Online.env == 'test'
        @queue.empty_bucket 
      else
        raise "Can only purge all queues in the test environment"
      end
    end
  
    def push(message)
      @queue.write("#{@name}/#{(Time.now.utc.to_f * 10000).to_i}", message)
    end

    def pop
      # It never blocks
      keys = @queue.keys("#{@name}/").sort
      keys.each do |key|
        begin
          msg = @queue.find(key)
          message = msg.value
          msg.delete
          return message
        rescue AWS::S3::NoSuchKey
          # ignore it. The bucket might have a key in it that's actually
          # been deleted, but someohow the bucket gets updated slowly and
          # think it's there. Weird, I know, but it's all asynchronous.  so
          # trudge on.
        end
      end
      return nil
    end
  end
end
