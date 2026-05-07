require_relative "test_helper"

ENV['NEO_DISABLE_END'] = 'true'
require_relative "../src/neo"

class NeoOutputTest < Minitest::Test
  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end

  def test_assertion_failure_does_not_print_the_answer
    failure = Neo::Assertions::FailedAssertionError.new("Expected 2 to equal 999999")
    failure.set_backtrace(["./about_asserts.rb:52:in `test_fill_in_values'", "./neo.rb:1"])

    sensei = Neo::Sensei.new
    sensei.instance_variable_set(:@failure, failure)

    output = capture_stdout { sensei.guide_through_error }

    refute_match(/Expected 2 to equal 999999/, output)
    refute_match(/The answers you seek/, output)
    assert_match(/The answer is hidden, so the discovery remains yours\./, output)
    assert_match(%r{about_asserts\.rb:52}, output)
  end

  def test_assert_nothing_raised_reports_the_actual_exception
    koan = Neo::Koan.new(:test_method)

    error = assert_raises(Neo::Assertions::FailedAssertionError) do
      koan.assert_nothing_raised { raise ArgumentError, "bad path" }
    end

    assert_match(/ArgumentError/, error.message)
    assert_match(/bad path/, error.message)
  end

  def test_runtime_error_prints_the_error_context
    failure = NameError.new("undefined local variable or method `answer'")
    failure.set_backtrace(["./about_methods.rb:10:in `test_method'", "./neo.rb:1"])

    sensei = Neo::Sensei.new
    sensei.instance_variable_set(:@failure, failure)

    output = capture_stdout { sensei.guide_through_error }

    assert_match(/NameError/, output)
    assert_match(/undefined local variable or method `answer'/, output)
    assert_match(%r{about_methods\.rb:10}, output)
  end
end
