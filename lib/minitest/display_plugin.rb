require_relative 'display'

# Minitest 5 plugin hook
module Minitest

  def self.plugin_display_init(options)
    self.reporter.reporters.reject! {|r| r.class == Minitest::ProgressReporter }
    self.reporter.reporters.unshift Minitest::Display::Reporter.new
  end

end

