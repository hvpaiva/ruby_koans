# frozen_string_literal: true

require_relative "../test_helper"

# DATA-03 — bumping the curriculum is a deliberate review gate.
# If this test fails, you added or removed an exercise without updating
# Rubykoans::Curriculum::EXPECTED_EXERCISE_COUNT.
#
# PITFALLS.md §1: this is the lint that prevents the legacy
# `in_ruby_version` bug class — a curriculum that silently shrinks on a new
# Ruby major would fail this lint loudly.
class ExpectedExerciseCountLintTest < Minitest::Test
  def test_curriculum_size_matches_expected_count
    actual   = Rubykoans::Curriculum.load.size
    expected = Rubykoans::Curriculum::EXPECTED_EXERCISE_COUNT
    assert_equal expected, actual,
                 "info.yml has #{actual} exercises; " \
                 "Rubykoans::Curriculum::EXPECTED_EXERCISE_COUNT is #{expected}. " \
                 "Bump the constant deliberately when adding/removing exercises."
  end
end
