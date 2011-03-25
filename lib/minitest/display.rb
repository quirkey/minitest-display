require 'benchmark'

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
  def _run_suite(suite, type)
    if display.options[:suite_names] && display.printable_suite?(suite)
      print display.color("\n#{suite}#{display.options[:suite_divider]}", :suite)
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
