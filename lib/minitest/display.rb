module MiniTest
  module Display
    ANSI_COLOR_CODES = {
      clear: "\e[0m",
      red: "\e[31m",
      green:"\e[32m",
      yellow: "\e[33m"
    }

    def self.options
      @options || {
        suite_names: true,
        suite_divider: " // ",
        color: true
      }
    end

    def self.options=(new_options)
      self.options.update(new_options)
    end
  end
end

class MiniTest::Unit
  # Monkey Patchin!
  def _run_suite(suite, type)
    printable_suite = suite.superclass == MiniTest::Unit::TestCase && suite != MiniTest::Spec
    print "#{suite}#{display.options[:suite_divider]}" if display.options[:suite_names] && printable_suite

    filter = options[:filter] || '/./'
    filter = Regexp.new $1 if filter =~ /\/(.*)\//

    assertions = suite.send("#{type}_methods").grep(filter).map { |method|
      inst = suite.new method
      inst._assertions = 0

      print "#{suite}##{method} = " if @verbose

      @start_time = Time.now
      result = inst.run self
      time = Time.now - @start_time

      print "%.2f s = " % time if @verbose
      print result
      puts if @verbose

      inst._assertions
    }

    return assertions.size, assertions.inject(0) { |sum, n| sum + n }
  end

  private
  def display
    ::MiniTest::Display
  end
end
