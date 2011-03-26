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
    VERSION = '0.0.1'

    class << self
      def options
        @options ||= {
          suite_names: true,
          suite_divider: " | ",
          color: true,
          wrap_at: 80,
          print: {
            success: '.',
            failure: 'F',
            error: 'E'
          },
          colors: {
            clear: "\e[0m",
            red: "\e[31m",
            green:"\e[32m",
            yellow: "\e[33m",

            suite: :clear,
            success: :green,
            failure: :red,
            error: :red
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
        if color.is_a?(Symbol)
          if c = options[:colors][color]
            tint(c)
          end
        else
          color
        end
      end

      DONT_PRINT_CLASSES = %w{
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

class MiniTest::Unit
  # Monkey Patchin!
  def _run_anything(type)
    suites = TestCase.send "#{type}_suites"
    return if suites.empty?

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

    status
  end

  def _run_suite(suite, type)
    suite_header = ""
    if display.options[:suite_names] && display.printable_suite?(suite)
      suite_header = suite.to_s
      print display.color("\n#{suite_header}#{display.options[:suite_divider]}", :suite)
    end

    filter = options[:filter] || '/./'
    filter = Regexp.new $1 if filter =~ /\/(.*)\//

    wrap_at = display.options[:wrap_at] - suite_header.length
    wrap_count = wrap_at

    assertions = suite.send("#{type}_methods").grep(filter).map { |method|
      inst = suite.new method
      inst._assertions = 0

      print "#{suite}##{method} = " if @verbose

      @start_time = Time.now
      result = inst.run self
      time = Time.now - @start_time

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

      wrap_count -= 1
      if wrap_count == 0
        print "\n#{' ' * suite_header.length}#{display.options[:suite_divider]}"
        wrap_count = wrap_at
      end

      inst._assertions
    }

    return assertions.size, assertions.inject(0) { |sum, n| sum + n }
  end

  def status(io = self.output)
    format = "%d tests, %d assertions, %d failures, %d errors, %d skips"
    final_status = failures + errors > 0 ? :failure : :success
    io.puts display.color(format % [test_count, assertion_count, failures, errors, skips], final_status)
  end

  private
  def display
    ::MiniTest::Display
  end
end
