require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require File.join(File.dirname(__FILE__), 'lib', 'minitest', 'display')
require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "minitest-display"
  gem.version = MiniTest::Display::VERSION
  gem.homepage = "http://github.com/quirkey/minitest-display"
  gem.license = "MIT"
  gem.summary = %Q{Patches MiniTest to allow for an easily configurable output. For Ruby 1.9 :D}
  gem.description = %Q{Patches MiniTest to allow for an easily configurable output. For Ruby 1.9 :Datches MiniTest to allow for an easily configurable output. For Ruby 1.9 :D. Inspired by leftright, redgreen and other test output gems, with an emphasis on configuration and style}
  gem.email = "aaron@quirkey.com"
  gem.authors = ["Aaron Quint"]
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test
