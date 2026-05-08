# frozen_string_literal: true

require_relative "test_helper"
require "pathname"

class ExerciseTest < Minitest::Test
  def make(**overrides)
    defaults = {
      name:                 "sample",
      dir:                  "00_intro",
      path:                 Pathname("exercises/00_intro/sample.rb"),
      test?:                false,
      hints:                ["hint 1"],
      solution_path:        Pathname("solutions/00_intro/sample.rb"),
      concepts_introduced:  ["workflow"],
      concepts_required:    [],
      skip_check_unsolved?: true,
    }
    Rubykoans::Exercise.new(**defaults.merge(overrides))
  end

  def test_construct_with_all_keyword_args
    ex = make
    assert_equal "sample", ex.name
    assert_equal "00_intro", ex.dir
    refute ex.test?
    assert ex.skip_check_unsolved?
  end

  def test_value_equality
    assert_equal make, make
  end

  def test_missing_required_arg_raises
    assert_raises(ArgumentError) do
      Rubykoans::Exercise.new(
        name: "x", dir: "x", path: Pathname("x"), test?: false,
        hints: [], solution_path: Pathname("x")
        # concepts_introduced + concepts_required + skip_check_unsolved? missing
      )
    end
  end
end
