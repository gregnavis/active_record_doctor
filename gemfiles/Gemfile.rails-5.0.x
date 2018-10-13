source 'https://rubygems.org'
gemspec path: File.join(File.dirname(__FILE__), '..')

gem 'rails', '~> 5.0.0'

# Rails 5.0 is buggy and doesn't work with newer versions of minitest.
gem 'minitest', '5.10.3'