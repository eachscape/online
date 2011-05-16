require 'test_helper'
require 'online_storage_tests'

class TestMockOnlineStorage < Test::Unit::TestCase
  include OnlineStorageTests

  def setup
    Online.mock!
    WebMock.disable_net_connect!
    super
  end
end
