module Online
  module Test
    # A fake version of Online::Storage, for use by unit tests that don't
    # want to connect to the network.
    class MockStorage
    end
  end
end
