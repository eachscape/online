require 'test_helper'
require 'online_queue_tests'

class TestMockOnlineQueue < Test::Unit::TestCase
  include OnlineQueueTests

  def setup
    Online.mock!(false)
    super
  end
end
