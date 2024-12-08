# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

require "active_record_doctor/version"

ACTIVE_RECORD_SPEC = ">= 7.0.0"

Gem::Specification.new do |s|
  s.name     = "active_record_doctor"
  s.version  = ActiveRecordDoctor::VERSION
  s.authors  = ["Greg Navis"]
  s.email    = ["contact@gregnavis.com"]
  s.homepage = "https://github.com/gregnavis/active_record_doctor"
  s.summary  = "Identify database issues before they hit production."
  s.license  = "MIT"
  s.files    = Dir["lib/**/*", "MIT-LICENSE.txt", "README.md"]

  s.metadata["rubygems_mfa_required"] = "true"

  s.required_ruby_version = ">= 3.1.0"

  s.add_dependency "activerecord", ACTIVE_RECORD_SPEC

  s.add_development_dependency "minitest-fork_executor", "~> 1.0.2"
  s.add_development_dependency "mysql2", "~> 0.5.6"
  s.add_development_dependency "pg", "~> 1.5.9"
  s.add_development_dependency "railties", ACTIVE_RECORD_SPEC
  s.add_development_dependency "rake", "~> 13.2.1"
  s.add_development_dependency "rubocop", "~> 1.68.0"
  s.add_development_dependency "sqlite3", "~> 2.2.0"
  s.add_development_dependency "transient_record", "~> 2.0.0"
end
