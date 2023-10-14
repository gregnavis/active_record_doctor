source "https://rubygems.org"
gemspec path: File.join(File.dirname(__FILE__), "..")

gem "activerecord", "~> 6.0.0"

# Older versions don't work with Ruby 3.0.
gem "pg", "~> 1.3.0"
gem "mysql2", "~> 0.5.3"
