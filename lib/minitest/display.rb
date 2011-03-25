require 'benchmark'

module MiniTest
  module Display

    class << self
      def options
        @options || {
          suite_names: true,
          suite_divider: " // ",
          color: true,
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
        self.options.update(new_options)
      end

      def color(string, color)
        return string unless options[:color]
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
    end

  end
end

class MiniTest::Unit
  # Monkey Patchin!
  def _run_suite(suite, type)
    printable_suite = suite.superclass == MiniTest::Unit::TestCase && suite != MiniTest::Spec
    if display.options[:suite_names] && printable_suite
      print display.color("#{suite}#{display.options[:suite_divider]}", :suite)
    end

    filter = options[:filter] || '/./'
    filter = Regexp.new $1 if filter =~ /\/(.*)\//

    assertions = suite.send("#{type}_methods").grep(filter).map { |method|
      inst = suite.new method
      inst._assertions = 0

      print "#{suite}##{method} = " if @verbose

      result = nil
      time = Benchmark.realtime {
        result = inst.run self
      }

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

      inst._assertions
    }

    return assertions.size, assertions.inject(0) { |sum, n| sum + n }
  end

  private
  def display
    ::MiniTest::Display
  end
end
