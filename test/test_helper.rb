require 'rubygems'
require 'bundler/setup'

require 'test/unit'
require 'online'

# Set up a directory that we can use to simulate S3.
Online.mock_storage_directory =
  File.expand_path(File.join(File.dirname(__FILE__), '..', 'mock_storage'))
