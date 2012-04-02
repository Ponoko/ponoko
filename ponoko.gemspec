# -*- encoding: utf-8 -*-

require 'rake'

$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/lib")
require "ponoko/version"

Gem::Specification.new do |s|
  s.name        = "ponoko"
  s.version     = Ponoko::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Henry Maddocks"]
  s.email       = ["henry@ponoko.com"]
  s.homepage    = "http://www.ponoko.com/app-gateway/developer-program"
  s.summary     = %q{Ruby interface to your Ponoko Personal Factory}

  s.rubyforge_project = "ponoko"

  s.add_dependency "oauth", "~> 0.4.4"  
  s.add_dependency "json"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "minitest", ">= 2.5.1"

  s.files = FileList['lib/**/*.rb', '[A-Z]*', 'test/**/*'].to_a  

end
