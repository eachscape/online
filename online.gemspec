# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "online/version"

Gem::Specification.new do |s|
  s.name        = "online"
  s.version     = Online::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Bob Fitterman", "Eric Kidd"]
  s.email       = ["bob@eachscape.com", "eric@kiddsoftware.com"]
  s.summary     = %q{Interface to S3 storage and queuing}
  #s.description = %q{}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency('aws-s3', '>= 0.6.2')
end
