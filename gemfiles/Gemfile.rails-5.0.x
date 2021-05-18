source 'https://rubygems.org'
gemspec path: File.join(File.dirname(__FILE__), '..')

gem 'rails', '~> 5.0.0'

case ENV.fetch("DATABASE")
when "postgresql"
  gem 'pg', '~> 1.0.0'
when "mysql"
  gem 'mysql2', '~> 0.5.3'
end
