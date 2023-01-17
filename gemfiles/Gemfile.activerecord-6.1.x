source "https://rubygems.org"
gemspec path: File.join(File.dirname(__FILE__), "..")

gem "activerecord", "~> 6.1.0"

# Older versions result in lots of warnings in Ruby 2.7.
gem "pg", "~> 1.4.5"
gem "mysql2", "~> 0.5.3"
