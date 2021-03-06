require 'test_helper'
require 'online_storage_tests'

class TestOnlineStorage < Test::Unit::TestCase
  include OnlineStorageTests

  def setup
    Online.mock!(false)
    WebMock.allow_net_connect!
    super
  end
end
