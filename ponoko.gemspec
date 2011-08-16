# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
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

  s.add_dependency "oauth"
  s.add_development_dependency "simplecov"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test}/*`.split("\n")
  s.require_paths = ["lib"]
  
end
