require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/testtask'

task :default => :test

desc "Run unit tests"
Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/test_*.rb'] - ['test/test_helper.rb']
end
