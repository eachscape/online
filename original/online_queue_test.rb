require 'test_helper'

class OnlineQueueTest < ActiveSupport::TestCase
  # This tests real queues
  def setup
    @queue = OnlineQueue.new('first')
    @queue.purge_all_queues
  end

  def test_push_pop_queue
    @queue.push 'a'
    0.upto(100000) {|i| i} # spin your wheels for a bit
    @queue.push 'b'
    msg = @queue.pop
    assert_equal 'a', msg
    msg = @queue.pop
    assert_equal 'b', msg
    msg = @queue.pop
    assert_nil msg
  end

  def test_two_queues
    second = OnlineQueue.new('second')
    @queue.push 'a'
    second.push 'b'
    0.upto(100000) {|i| i} # spin your wheels for a bit
    @queue.push 'c'
    second.push 'd'
    msg = @queue.pop
    assert_equal 'a', msg
    msg = @queue.pop
    assert_equal 'c', msg
    msg = @queue.pop
    assert_nil msg
    msg = second.pop
    assert_equal 'b', msg
    msg = second.pop
    assert_equal 'd', msg
    msg = second.pop
    assert_nil msg
  end
end
