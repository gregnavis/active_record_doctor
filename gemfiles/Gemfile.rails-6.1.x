source 'https://rubygems.org'
gemspec path: File.join(File.dirname(__FILE__), '..')

gem 'rails', '~> 6.1.0'

# Older versions result in lots of warnings in Ruby 2.7.
gem 'pg', '>= 1.2.0'