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
  # Include your dependencies below. Runtime dependencies are required when using your gem,
  # and development dependencies are only needed for development (ie running rake tasks, tests, etc)
  gem.add_runtime_dependency 'minitest', '~> 2.0.2'
  #  gem.add_development_dependency 'rspec', '> 1.2.3'
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "minitest-display #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
