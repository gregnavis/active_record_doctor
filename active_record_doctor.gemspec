# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

require "active_record_doctor/version"

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

  s.required_ruby_version = ">= 2.1.0"

  rails_version = ">= 4.2"

  s.add_dependency "activerecord", rails_version
  s.add_dependency "activesupport", rails_version
  s.add_dependency "railties", rails_version

  s.add_development_dependency "minitest-fork_executor", "~> 1.0"
  s.add_development_dependency "pg", "~> 1.1"
  s.add_development_dependency "rails", rails_version

  # We can't use rubocop for older Rubies so we just skip it and rely on
  # linting performed with newer ones.
  s.add_development_dependency "rubocop", "~> 1.14.0" unless ENV["SKIP_RUBOCOP"]
end
