# frozen_string_literal: true

begin
  require "bundler/setup"
rescue LoadError
  puts "You must `gem install bundler` and `bundle install` to run rake tasks"
end

require "rdoc/task"

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.title    = "ActiveRecordDoctor"
  rdoc.options << "--line-numbers"
  rdoc.rdoc_files.include("README.rdoc")
  rdoc.rdoc_files.include("lib/**/*.rb")
end

Bundler::GemHelper.install_tasks

require "rubocop/rake_task"
RuboCop::RakeTask.new

require "rake/testtask"

namespace :test do
  ["postgresql", "mysql2", "sqlite3"].each do |adapter|
    Rake::TestTask.new(adapter) do |t|
      t.deps = ["prepare_#{adapter}"]
      t.libs = ["lib", "test"]
      t.ruby_opts = ["-rsetup"]
      t.pattern = "test/**/*_test.rb"
      t.verbose = false

      # Hide warnings emitted by our dependencies.
      t.warning = false
    end

    task :"prepare_#{adapter}" do
      ENV["DATABASE_ADAPTER"] = adapter
    end
  end
end

task test: ["test:postgresql", "test:mysql2", "test:sqlite3"]

task default: :test
