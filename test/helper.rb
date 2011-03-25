require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'minitest/autorun'
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'minitest/display'
$print_runs = ENV['DEBUG']

class MiniTest::Unit::TestCase
  attr_reader :suite_output

  def capture_test_output(testcase_str)
    base_dir = File.expand_path(File.dirname(__FILE__))
    lib_dir =  File.expand_path(File.join(base_dir, '..', 'lib'))
    tmpdir = File.join(base_dir, "tmp")
    FileUtils.mkdir_p(tmpdir)
    tmpfilename = "#{tmpdir}/test_suite.rb"
    header = %{
      require 'minitest/autorun'
      require '#{lib_dir}/minitest/display'
    }

    testcase_str = header + "\n" + testcase_str
    File.unlink(tmpfilename) if File.readable?(tmpfilename)
    File.open(tmpfilename, 'w') {|f| f << testcase_str }
    cmd = %[`which ruby` #{tmpfilename} 2>&1]

    @suite_output = %x[#{cmd}]
    if $print_runs
      puts "-------"
      puts @suite_output
      puts "-------"
    end
  end

  def assert_output(duck)
    if duck.is_a? Regexp
      assert_match duck, strip_color(suite_output)
    else
      assert strip_color(suite_output).include?(duck.to_s)
    end
  end

  def assert_no_output(duck)
    if duck.is_a? Regexp
      assert_no_match duck, strip_color(suite_output)
    else
      assert ! strip_color(suite_output).include?(duck.to_s)
    end
  end

  def strip_color(string)
    string.gsub(/\e\[(?:[34][0-7]|[0-9])?m/, '') # thanks again term/ansicolor
  end
end
