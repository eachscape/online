require 'rubygems'
require 'bundler/setup'

require 'test/unit'
require 'online'

# Fake Rails implementation for now.
module Rails
  def self.env
    'test'
  end
end
