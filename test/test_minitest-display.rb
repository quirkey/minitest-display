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

  end

  def test_runs_basic_test_with_multiple_suites

  end

  def test_runs_basic_test_with_slow_output

  end
end
