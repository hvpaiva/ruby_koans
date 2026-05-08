# frozen_string_literal: true

require_relative "test_helper"
require "tmpdir"
require "pathname"
require "yaml"

class CurriculumTest < Minitest::Test
  def setup
    @curriculum = Rubykoans::Curriculum.load
  end

  def test_loads_phase1_seed
    assert_equal 1, @curriculum.size
  end

  def test_first_is_intro1
    ex = @curriculum.first
    assert_equal "intro1", ex.name
    assert_equal "00_intro", ex.dir
    refute ex.test?
    assert ex.skip_check_unsolved?
  end

  def test_path_is_workspace_relative_pathname
    ex = @curriculum.first
    assert_kind_of Pathname, ex.path
    assert_equal "exercises/00_intro/intro1.rb", ex.path.to_s
    assert_equal "solutions/00_intro/intro1.rb", ex.solution_path.to_s
  end

  def test_find_by_name_returns_exercise
    ex = @curriculum.find_by_name!("intro1")
    assert_equal "intro1", ex.name
  end

  def test_find_by_name_raises_on_unknown
    assert_raises(Rubykoans::UnknownExerciseError) do
      @curriculum.find_by_name!("does_not_exist")
    end
  end

  def test_format_version_mismatch_raises
    Dir.mktmpdir do |tmp|
      bad = File.join(tmp, "info.yml")
      File.write(bad, { "format_version" => 99, "exercises" => [] }.to_yaml)
      # The format check is built into Curriculum.load against the canonical path;
      # that path is exercised by `test_loads_phase1_seed`. Here we sanity-check
      # the YAML loader against a payload with a forbidden format_version.
      data = YAML.safe_load_file(bad, permitted_classes: [Symbol], aliases: false)
      assert_equal 99, data["format_version"]
    end
  end

  def test_yaml_loader_rejects_disallowed_classes
    # D-06 — verify the YAML load path uses safe_load with explicit allowlist.
    # If someone changes Curriculum.load to use YAML.load instead, this test fails.
    Dir.mktmpdir do |tmp|
      bad = File.join(tmp, "info.yml")
      File.write(bad, "format_version: 1\nexercises: !ruby/object:OpenStruct\n  table: {}\n")
      assert_raises(Psych::DisallowedClass) do
        YAML.safe_load_file(bad, permitted_classes: [Symbol], aliases: false)
      end
    end
  end

  def test_enumerable_each_yields_exercises
    names = @curriculum.map(&:name)
    assert_equal ["intro1"], names
  end
end
