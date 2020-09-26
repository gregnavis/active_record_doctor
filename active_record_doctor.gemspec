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
  s.summary     = "Identify database issues before they hit production."
  s.license     = "MIT"

  s.files = Dir["lib/**/*", "MIT-LICENSE.txt", "README.md"]
  s.test_files = Dir["test/**/*"]

  rails_version = ">= 4.2"

  s.add_dependency "railties", rails_version
  s.add_dependency "activerecord", rails_version
  s.add_dependency "activesupport", rails_version

  s.add_development_dependency "rails", rails_version
  s.add_development_dependency "temping", "~> 3.10"
  s.add_development_dependency "minitest-fork_executor", '~> 1.0'
end
