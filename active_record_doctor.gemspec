# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

require "active_record_doctor/version"

ACTIVE_RECORD_SPEC = ">= 4.2.0"

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

  s.add_dependency "activerecord", ACTIVE_RECORD_SPEC

  s.add_development_dependency "minitest-fork_executor", "~> 1.0.2"
  s.add_development_dependency "mysql2", "~> 0.5.3"
  s.add_development_dependency "pg", "~> 1.1.4"
  s.add_development_dependency "railties", ACTIVE_RECORD_SPEC
  s.add_development_dependency "rake", "~> 12.3.3"
  s.add_development_dependency "transient_record", "= 2.0.0.rc2"

  # We don't install rubocop in CI because we test against older Rubies that
  # are incompatible with Rubocop.
  if ENV["CI"].nil? || ENV["LINT"]
    s.add_development_dependency "rubocop", "~> 1.14.0"
  end
end
