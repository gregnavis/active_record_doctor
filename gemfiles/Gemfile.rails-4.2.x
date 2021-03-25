source 'https://rubygems.org'
gemspec path: File.join(File.dirname(__FILE__), '..')

gem 'rails', '~> 4.2.0'

# We're testing this version of Rails against older Rubies and can't use
# a newer version of pg.
gem 'pg', '<= 0.20'
