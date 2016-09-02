$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "active_record_doctor/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "active_record_doctor"
  s.version     = ActiveRecordDoctor::VERSION
  s.authors     = ["Greg Navis"]
  s.email       = ["contact@gregnavis.com"]
  s.homepage    = "https://github.com/gregnavis/active_record_doctor"
  s.summary     = "A cure for your Active Record ailments."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE.txt", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "< 5.1", ">= 4.2"

  s.add_development_dependency "rails", "< 5.1", ">= 4.2"
  s.add_development_dependency "sqlite3", "~> 1.3"
  s.add_development_dependency "rake", "~> 11.1"
end
