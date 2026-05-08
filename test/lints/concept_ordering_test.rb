# frozen_string_literal: true

require_relative "../test_helper"
require "set"

# DATA-04 — fresh-learner walk simulator.
# Walk info.yml in declared order; maintain a Set of "concepts known so far"
# (each exercise's concepts_introduced is added to the set AFTER its required
# concepts are checked against the set). Any exercise whose concepts_required
# is not a subset of the known set is an ordering bug — fail loudly with the
# exercise name and missing concepts.
#
# PITFALLS.md §3 ("Exercise ordering bugs") and §13 ("Curriculum dependency
# knots") — this lint catches both.
class ConceptOrderingLintTest < Minitest::Test
  def test_every_required_concept_is_introduced_earlier
    known = Set.new
    Rubykoans::Curriculum.load.each do |exercise|
      missing = exercise.concepts_required - known.to_a
      assert_empty missing,
                   "exercise #{exercise.name.inspect} requires concepts " \
                   "#{missing.inspect} that have not been introduced by an " \
                   "earlier exercise. " \
                   "Reorder info.yml or update the exercise's concepts_introduced."
      known.merge(exercise.concepts_introduced)
    end
  end
end
