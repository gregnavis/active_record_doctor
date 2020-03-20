source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}.git" }

gemspec path: File.join(File.dirname(__FILE__), '..')

gem 'rails', '~> 5.2', github: 'rails/rails', branch: '5-2-stable'
