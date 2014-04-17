require 'minitest/unit'

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

module MiniTest
  module Display
    VERSION = '0.2.0.pre2'

    class << self
      def options
        @options ||= {
          :suite_names => true,
          :suite_divider => " | ",
          :suite_field_formatter => false, # Examples: 1 line output: " | %s", multi-line output: "\n %s"
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
    end

  end
end

class MiniTest::Display::Runner < MiniTest::Unit

  def initialize(*args)
    super
    @recorders = []
  end

  # Add a recorder which for each test that has a `record`.
  # Optionally can also have an:
  #
  # `record_tests_started`,
  # `record_suite_started(suite)`,
  # `record(suite, method, assertions, time, error)`
  # `record_suite_finished(suite, assertions, time)`,
  # `record_tests_finished(report, test_count, assertion_count, time)
  #
  # (Executed in that order)
  #
  def add_recorder(new_recorder)
    new_recorder_instance = new_recorder.new(self)
    @recorders << new_recorder_instance
  end

  def record_suite_started(suite)
    run_recorder_method(:record_suite_started, suite)
  end

  def record_suite_finished(suite, assertions, time)
    run_recorder_method(:record_suite_finished, suite, assertions, time)
  end

  def record_tests_started
    run_recorder_method(:record_tests_started)
  end

  def record_tests_finished(report, test_count, assertion_count, time)
    run_recorder_method(:record_tests_finished, report, test_count, assertion_count, time)
  end

  def record(suite, method, assertions, time, error)
    run_recorder_method(:record, suite, method, assertions, time, error)
  end

  # Patched _run_anything
  def _run_anything type
    suites = TestCase.send "#{type}_suites"
    return if suites.empty?

    # PATCH
    record_tests_started
    # END
    start = Time.now

    puts
    puts "# Running #{type}s:"
    puts

    @test_count, @assertion_count = 0, 0
    sync = output.respond_to? :"sync=" # stupid emacs
    old_sync, output.sync = output.sync, true if sync

    results = _run_suites suites, type

    @test_count      = results.inject(0) { |sum, (tc, _)| sum + tc }
    @assertion_count = results.inject(0) { |sum, (_, ac)| sum + ac }

    output.sync = old_sync if sync

    t = Time.now - start

    puts
    puts
    puts "Finished #{type}s in %.6fs, %.4f tests/s, %.4f assertions/s." %
      [t, test_count / t, assertion_count / t]

    report.each_with_index do |msg, i|
      puts "\n%3d) %s" % [i + 1, msg]
    end

    puts

    # PATCH
    record_tests_finished(report, test_count, assertion_count, t)
    # END
    status
  end

  # Patched _run_suite
  def _run_suite(suite, type)
    header = "#{type}_suite_header"
    suite_header = send(header, suite) if respond_to? header

    # PATCH
    if display.options[:suite_names] && display.printable_suite?(suite)
      suite_header ||= suite.to_s

      if display.options[:suite_field_formatter]
        print display.color("\n#{suite_header}#{display.options[:suite_field_formatter]}" % '', :suite)
      else
        print display.color("\n#{suite_header}#{display.options[:suite_divider]}", :suite)
      end
    end

    suite_header_length = suite_header ? suite_header.length : 0
    # END

    filter = options[:filter] || '/./'
    filter = Regexp.new $1 if filter =~ /\/(.*)\//

    # PATCH
    wrap_at = display.options[:wrap_at] - suite_header_length if suite_header
    wrap_count = wrap_at

    record_suite_started(suite)
    full_start_time = Time.now
    @test_times ||= Hash.new { |h, k| h[k] = [] }

    #END
    assertions = suite.send("#{type}_methods").grep(filter).map { |method|
      inst = suite.new method
      inst._assertions = 0

      print "#{suite}##{method} = " if @verbose

      # PATCH
      start_time = Time.now
      # END
      result = inst.run self

      # PATCH
      time = Time.now - start_time
      @test_times[suite] << ["#{suite}##{method}", time]

      print "%.2f s = " % time if @verbose
      print case result
      when "."
        display.color(display.options[:print][:success], :success)
      when "F"
        display.color(display.options[:print][:failure], :failure)
      when "E"
        display.color(display.options[:print][:error], :error)
      else
        result
      end

      puts if @verbose

      unless wrap_count.nil?
        wrap_count -= 1

        if wrap_count == 0
          if display.options[:suite_field_formatter]
            print display.options[:suite_field_formatter] % ''
          else
            print "\n#{' ' * suite_header_length}#{display.options[:suite_divider]}"
          end

          wrap_count = wrap_at
        end
      end

      inst._assertions
    }

    total_time = Time.now - full_start_time

    record_suite_finished(suite, assertions, total_time)

    if suite_header && assertions.length > 0 && display.options[:suite_time]
      if display.options[:suite_field_formatter]
        print display.options[:suite_field_formatter] % ("%.2f s" % total_time)
      else
        print "\n#{' ' * suite_header_length}#{display.options[:suite_divider]}"
        print "%.2f s" % total_time
      end
    end

    return assertions.size, assertions.inject(0) { |sum, n| sum + n }
  end

  def status(io = self.output)
    format = "%d tests, %d assertions, %d failures, %d errors, %d skips"
    final_status = if errors > 0 then :error
                   elsif failures > 0 then :failure
                   else :success
                   end
    io.puts display.color(format % [test_count, assertion_count, failures, errors, skips], final_status)

    display_slow_tests if display.options[:output_slow]
    display_slow_suites if display.options[:output_slow_suites]
  end

  def display_slow_tests
    times = @test_times.values.flatten(1).sort { |a, b| b[1] <=> a[1] }
    puts "Slowest tests:"
    times[0..display.options[:output_slow].to_i].each do |test_name, time|
      puts "%.2f s\t#{test_name}" % time
    end
  end

  def display_slow_suites
    times = @test_times.map { |suite, tests| [suite, tests.map(&:last).inject {|sum, n| sum + n }] }.sort { |a, b| b[1] <=> a[1] }
    puts "Slowest suites:"
    times[0..display.options[:output_slow_suites].to_i].each do |suite, time|
      puts "%.2f s\t#{suite}" % time
    end
  end

  private
  def run_recorder_method(method, *args)
    @recorders.each do |recorder|
      if recorder.respond_to?(method)
        recorder.send method, *args
      end
    end
  end

  def display
    ::MiniTest::Display
  end
end

MiniTest::Unit.runner = MiniTest::Display::Runner.new
