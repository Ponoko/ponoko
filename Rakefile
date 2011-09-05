require 'rake/testtask'
# require 'ponoko'

include Rake::DSL

Rake::TestTask.new do |t|
  t.libs << 'test' << 'lib'
  t.test_files = Dir.glob("test/**/test_*.rb")
end

task :default => :test

namespace "ponoko" do

  desc "Get an access token"
  task "authorise" do
    Ponoko::OAuthAPI.authorize
  end  
end
