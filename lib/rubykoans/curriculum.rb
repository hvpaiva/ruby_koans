# frozen_string_literal: true

require "yaml"
require "pathname"
require_relative "exercise"

module Rubykoans
  # Raised when `data/info.yml` declares a `format_version` other than
  # `Curriculum::EXPECTED_FORMAT_VERSION`. A bumped format_version is the
  # signal that the manifest schema changed; refusing to load is the
  # safest response.
  class UnsupportedFormatError < Rubykoans::Error; end

  # Raised by `Curriculum#find_by_name!` when no exercise matches the given
  # name. This is a 1:1 mapping; we never silently fall back to the first
  # exercise (PITFALLS.md §1 — silent gates are the legacy bug class).
  class UnknownExerciseError < Rubykoans::Error; end

  # Curriculum is the in-memory model of `data/info.yml`. Construct it via
  # `Curriculum.load` — never instantiate by hand.
  #
  # Behaviour (DATA-01..05):
  #   - Loads `data/info.yml` via `YAML.safe_load_file` with explicit
  #     `permitted_classes: [Symbol]` and `aliases: false` (D-06 mandate).
  #   - Returns a Curriculum holding an ordered, frozen Array<Exercise>.
  #   - Raises `UnsupportedFormatError` if `format_version` does not match.
  #   - Exposes Enumerable so `curriculum.map(&:name)` works for lints.
  class Curriculum
    include Enumerable

    # The schema version this Curriculum understands. Bump when info.yml
    # gains a breaking field change.
    EXPECTED_FORMAT_VERSION = 1

    # DATA-03 — Phase 1 ships exactly 1 exercise (intro1). Phases 3-5 bump
    # this constant as exercises land. `test/lints/expected_exercise_count_test.rb`
    # asserts the constant matches the actual info.yml entry count, so a
    # silent drift is impossible.
    EXPECTED_EXERCISE_COUNT = 1

    attr_reader :welcome_message, :final_message

    def self.load
      path = gem_data_dir.join("info.yml")
      data = YAML.safe_load_file(
        path,
        permitted_classes: [Symbol],
        aliases:           false,
      )

      unless data["format_version"] == EXPECTED_FORMAT_VERSION
        raise UnsupportedFormatError,
              "info.yml format_version=#{data["format_version"].inspect}, " \
              "expected #{EXPECTED_FORMAT_VERSION}"
      end

      exercises = Array(data["exercises"]).map do |entry|
        # DATA-02 — `path` and `solution_path` may be explicit overrides OR
        # derived from `dir`/`name`. Explicit values win when present; this
        # gives Phase 3+ a way to opt out of the convention without breaking
        # Phase-1 entries that rely on derivation.
        exercise_path = if entry.key?("path") && !entry["path"].to_s.empty?
                          Pathname(entry["path"])
                        else
                          Pathname("exercises/#{entry["dir"]}/#{entry["name"]}.rb")
                        end

        solution_path = if entry.key?("solution_path") && !entry["solution_path"].to_s.empty?
                          Pathname(entry["solution_path"])
                        else
                          Pathname("solutions/#{entry["dir"]}/#{entry["name"]}.rb")
                        end

        Exercise.new(
          name:                 entry.fetch("name"),
          dir:                  entry.fetch("dir"),
          path:                 exercise_path,
          test?:                entry.fetch("test", true),
          hints:                Array(entry["hints"]),
          solution_path:        solution_path,
          concepts_introduced:  Array(entry["concepts_introduced"]),
          concepts_required:    Array(entry["concepts_required"]),
          skip_check_unsolved?: entry.fetch("skip_check_unsolved", false),
        )
      end

      new(
        exercises:       exercises,
        welcome_message: data["welcome_message"].to_s,
        final_message:   data["final_message"].to_s,
      )
    end

    # Path to the `data/` directory that ships with the gem. From
    # `lib/rubykoans/curriculum.rb` it's two `..` up.
    def self.gem_data_dir
      Pathname(__dir__).join("..", "..", "data").expand_path
    end

    def initialize(exercises:, welcome_message:, final_message:)
      @exercises       = exercises.freeze
      @welcome_message = welcome_message
      @final_message   = final_message
    end

    def first
      @exercises.first
    end

    def each(&block)
      @exercises.each(&block)
    end

    def size
      @exercises.size
    end

    def to_a
      @exercises.dup
    end

    def find_by_name!(name)
      @exercises.find { |e| e.name == name } or
        raise UnknownExerciseError, "no exercise named #{name.inspect}"
    end
  end
end
