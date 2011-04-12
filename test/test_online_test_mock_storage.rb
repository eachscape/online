require 'test_helper'
require 'online_storage_tests'

class TestOnlineTestMockStorage < Test::Unit::TestCase
  include OnlineStorageTests

  def setup
    Online.mock!
    super
  end
end
