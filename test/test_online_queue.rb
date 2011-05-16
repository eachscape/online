require 'test_helper'
require 'online_queue_tests'

class TestOnlineQueue < Test::Unit::TestCase
  include OnlineQueueTests

  def setup
    Online.mock!(false)
    WebMock.allow_net_connect!
    super
  end
end
