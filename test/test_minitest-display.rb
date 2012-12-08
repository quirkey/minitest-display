require 'helper'

class TestMinitestDisplay < MiniTest::Unit::TestCase

  def test_runs_basic_test_with_default_settings
    capture_test_output <<-TESTCASE
      class BasicTest < MiniTest::Unit::TestCase

        def test_truth
          assert true
        end

        def test_equality
          assert_equal 'test', 'test'
        end
      end
    TESTCASE

    assert_output(/BasicTest/)
    assert_output(/\.\./)
  end

  def test_runs_basic_test_with_failures
    capture_test_output <<-TESTCASE
      class BasicTest < MiniTest::Unit::TestCase

        def test_truth
          assert false
        end

        def test_equality
          assert_equal 'test', 'test'
        end
      end
    TESTCASE

    assert_output(/BasicTest/)
    assert_output(/F/)
    assert_output(/\./)
  end

  def test_runs_basic_test_with_multiple_suites
    capture_test_output <<-TESTCASE
      class BasicTest < MiniTest::Unit::TestCase

        def test_truth
          assert false
        end

        def test_equality
          assert_equal 'test', 'test'
        end
      end

      class AnotherBasicTest < MiniTest::Unit::TestCase

        def test_truth
          assert false
        end

        def test_equality
          assert_equal 'test', 'test'
        end
      end
    TESTCASE

    assert_output(/^BasicTest |/)
    assert_output(/AnotherBasicTest |/)
    assert_output(/F/)
    assert_output(/\./)
  end

  def test_runs_basic_test_suite_with_different_printing
    capture_test_output <<-TESTCASE
      MiniTest::Display.options = {
        :suite_divider => ' // ',
        :print => {
          :success => 'PASS'
        }
      }
      class PrintTest < MiniTest::Unit::TestCase

        def test_truth
          assert false
        end

        def test_equality
          assert_equal 'test', 'test'
        end
      end
    TESTCASE

    assert_output(/PrintTest \/\//)
    assert_output(/F/)
    assert_output(/PASS/)
  end

  def test_runs_basic_test_with_slow_output
    capture_test_output <<-TESTCASE
      MiniTest::Display.options = {
        :suite_divider => ' // ',
        :print => {
          :success => 'PASS'
        },
        :output_slow => true
      }
      class PrintTest < MiniTest::Unit::TestCase

        def test_truth
          assert false
        end

        def test_equality
          assert_equal 'test', 'test'
        end
      end
    TESTCASE

    assert_output(/PrintTest \/\//)
    assert_output(/F/)
    assert_output(/PASS/)
    assert_output(/Slowest tests:/)
  end

  def test_adding_a_recorder
    capture_test_output <<-TESTCASE
      MiniTest::Display.options = {
        :suite_divider => ' // ',
        :print => {
          :success => 'PASS'
        }
      }
      class TestRecorder
        def initialize(runner)
          @runner = runner
        end

        def record(suite, method, assertions, time, error)
          puts "I just recorded \#{method}"
        end
      end

      MiniTest::Unit.runner.add_recorder TestRecorder

      class PrintTest < MiniTest::Unit::TestCase

        def test_truth
          assert false
        end

        def test_equality
          assert_equal 'test', 'test'
        end
      end
    TESTCASE

    assert_output(/PrintTest \/\//)
    assert_output(/F/)
    assert_output(/PASS/)
    assert_output(/I just recorded test_truth/)
  end
end
