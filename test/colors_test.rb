# frozen_string_literal: true

require_relative "test_helper"

class ColorsTest < Minitest::Test
  def test_no_color_env_disables_colors
    ENV["NO_COLOR"] = "1"
    refute Rubykoans::Colors.use_colors?
    assert_equal "hi", Rubykoans::Colors.red("hi")
  ensure
    ENV.delete("NO_COLOR")
  end

  def test_rubykoans_no_color_env_disables_colors
    ENV["RUBYKOANS_NO_COLOR"] = "1"
    refute Rubykoans::Colors.use_colors?
  ensure
    ENV.delete("RUBYKOANS_NO_COLOR")
  end

  def test_helpers_return_plain_strings_when_colors_off
    # We cannot guarantee $stdout.tty? in CI; only assert the structure
    # when colors are explicitly disabled.
    ENV["NO_COLOR"] = "1"
    assert_equal "msg", Rubykoans::Colors.green("msg")
    assert_equal "msg", Rubykoans::Colors.yellow("msg")
    assert_equal "msg", Rubykoans::Colors.dim("msg")
  ensure
    ENV.delete("NO_COLOR")
  end

  def test_no_pastel_or_colorize_runtime_dep
    # Phase-1 hard rule: no color gem in the rubykoans runtime tree. Inspect
    # the gemspec's declared runtime deps (not the ambient gem environment —
    # transitive dev-only deps like `rainbow` from `standard` are fine).
    forbidden = %w[pastel colorize tty-color rainbow]
    gemspec_path = File.expand_path("../rubykoans.gemspec", __dir__)
    spec = Gem::Specification.load(gemspec_path)
    runtime_deps = spec.runtime_dependencies.map(&:name)
    forbidden.each do |gem_name|
      refute_includes runtime_deps, gem_name,
                      "#{gem_name} must not be a runtime dep of rubykoans"
    end
  end
end
