require 'minitest'

class Hash
  unless method_defined?(:deep_merge!)

    def deep_merge!(other_hash)
      other_hash.each_pair do |k,v|
        tv = self[k]
        self[k] = tv.is_a?(Hash) && v.is_a?(Hash) ? tv.deep_merge(v) : v
      end
      self
    end

    def deep_merge(other_hash)
      dup.deep_merge!(other_hash)
    end

  end
end

module Minitest
  module Display
    VERSION = '0.3.1'

    class << self
      def options
        @options ||= {
          :suite_names => true,
          :suite_divider => " | ",
          :suite_time => true,
          :color => true,
          :wrap_at => 80,
          :output_slow => 5,
          :output_slow_suites => 5,
          :print => {
            :success => '.',
            :failure => 'F',
            :error => 'E'
          },
          :colors => {
            :clear => 0,
            :bold => 1,
            :italics => 3,
            :underline => 4,
            :inverse => 9,
            :strikethrough => 22,
            :bold_off => 23,
            :italics_off => 24,
            :underline_off => 27,
            :inverse_off => 29,
            :strikethrough_off => 30,
            :black => 30,
            :red => 31,
            :green => 32,
            :yellow => 33,
            :blue => 34,
            :magenta => 35,
            :cyan => 36,
            :white => 37,
            :default => 39,
            :bg_black => 40,
            :bg_red => 41,
            :bg_green => 42,
            :bg_yellow => 43,
            :bg_blue => 44,
            :bg_magenta => 45,
            :bg_cyan => 46,
            :bg_white => 47,
            :bg_default => 49,

            :suite => :clear,
            :success => :green,
            :failure => :red,
            :error => :yellow
          }
        }
      end

      def options=(new_options)
        self.options.deep_merge!(new_options)
      end

      def color(string, color)
        return string unless STDOUT.tty? && options[:color]
        tint(color) + string + tint(:clear)
      end

      def tint(color)
        case color
        when Array
          color.collect {|c| tint(c) }.join('')
        when Symbol
          if c = options[:colors][color]
            tint(c)
          end
        else
          "\e[#{color}m"
        end
      end

      DONT_PRINT_CLASSES = %w{
              ActionDispatch::IntegrationTest
              ActionController::IntegrationTest
              ActionController::TestCase
              ActionMailer::TestCase
              ActionView::TestCase
              ActiveRecord::TestCase
              ActiveSupport::TestCase
              Test::Unit::TestCase
              MiniTest::Unit::TestCase
              MiniTest::Spec}

      def printable_suite?(suite)
        !DONT_PRINT_CLASSES.include?(suite.to_s)
      end

      # Add a recorder which for each test that has a `record`.
      # Optionally can also have an:
      #
      # `record_tests_started`,
      # `record_suite_started(suite)`,
      # `record(suite, method, assertions, time, error)`
      # `record_suite_finished(suite, assertions, time)`,
      # `record_tests_finished(test_count, assertion_count, failure_count, error_count, time)
      #
      # (Executed in that order)
      #
      def add_recorder(new_recorder)
        new_recorder_instance = new_recorder.new(self)
        @recorders ||= []
        @recorders << new_recorder_instance
      end

      # An array of all the registered MiniTest::Display recorders
      def recorders
        @recorders || []
      end
    end

    class Reporter < ::Minitest::Reporter

      def initialize(*args)
        super
        @total_assertions = 0
        @total_errors = 0
        @total_failures = 0
        @total_tests = 0
      end

      def record_suite_started(suite)
        if display.options[:suite_names] && display.printable_suite?(suite)
          @suite_header = suite.to_s
          io.print display.color("\n#{@suite_header}#{display.options[:suite_divider]}", :suite)
          @wrap_at = display.options[:wrap_at] - @suite_header.length
          @wrap_count = @wrap_at
        end
        @suite_started = Time.now
        run_recorder_method(:record_suite_started, suite)
      end

      def record_suite_finished(suite)
        @suite_finished = Time.now
        time = @suite_finished.to_f - @suite_started.to_f
        io.print "\n#{' ' * @suite_header.length}#{display.options[:suite_divider]}"
        io.print "%.2f s" % time
        run_recorder_method(:record_suite_finished, suite, @assertions, time)
      end

      def start
        @test_times ||= Hash.new { |h, k| h[k] = [] }
        @tests_started = Time.now.to_f
        run_recorder_method(:record_tests_started)
      end

      def report
        record_suite_finished(@current_suite) if @current_suite
        io.puts
        display_slow_tests if display.options[:output_slow]
        display_slow_suites if display.options[:output_slow_suites]
        run_recorder_method(:record_tests_finished, @total_tests, @total_assertions, @total_failures, @total_errors, Time.now.to_f - @tests_started)
      end

      def record(result)
        suite = result.class
        if suite != @current_suite
          record_suite_finished(@current_suite) if @current_suite
          record_suite_started(suite)
          @assertions = 0
        end
        @assertions += result.assertions
        @total_assertions += result.assertions
        @total_tests += 1
        output = if result.error?
          @total_errors += 1
          display.color(display.options[:print][:error], :error)
        elsif result.failure
          @total_failures += 1
          display.color(display.options[:print][:failure], :failure)
        else
          display.color(display.options[:print][:success], :success)
        end

        io.print output

        @wrap_count -= 1
        if @wrap_count == 0
          io.print "\n#{' ' * @suite_header.length}#{display.options[:suite_divider]}"
          @wrap_count = @wrap_at
        end

        run_recorder_method(:record, suite, result.name, result.assertions, result.time, result.failure)
        @test_times[suite] << ["#{suite}##{result.name}", result.time]
        @current_suite = suite
      end

      def display_slow_tests
        times = @test_times.values.flatten(1).sort { |a, b| b[1] <=> a[1] }
        io.puts "Slowest tests:"
        times[0..display.options[:output_slow].to_i].each do |test_name, time|
          io.puts "%.2f s\t#{test_name.gsub(/%/, '%%')}" % time
        end
      end

      def display_slow_suites
        times = @test_times.map { |suite, tests| [suite, tests.map(&:last).inject {|sum, n| sum + n }] }.sort { |a, b| b[1] <=> a[1] }
        io.puts "Slowest suites:"
        times[0..display.options[:output_slow_suites].to_i].each do |suite, time|
          io.puts "%.2f s\t#{suite.name.gsub(/%/, '%%')}" % time
        end
      end

      private
      def run_recorder_method(method, *args)
        Minitest::Display.recorders.each do |recorder|
          if recorder.respond_to?(method)
            recorder.send method, *args
          end
        end
      end

      def display
        ::Minitest::Display
      end
    end

  end
end
