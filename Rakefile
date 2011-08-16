require 'bundler/gem_tasks'
require 'rake/testtask'


Rake::TestTask.new do |t|
  t.libs << 'test' << 'lib'
  t.test_files = Dir.glob("test/**/test_*.rb")
end

task :default => :test
