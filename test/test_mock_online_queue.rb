require 'test_helper'
require 'online_queue_tests'

class TestMockOnlineQueue < Test::Unit::TestCase
  include OnlineQueueTests

  def setup
    Online.mock!
    WebMock.disable_net_connect!
    super
  end
end
