# frozen_string_literal: true

require_relative "../test_helper"
require "find"

# DATA-05 / PITFALLS.md §1 — zero `RUBY_VERSION` prefix-regex comparisons in
# the runtime tree. The legacy bug `RUBY_VERSION =~ /^#{version}/` silently
# excluded keyword-arg + pattern-matching topics on Ruby 4. This lint makes
# that class of bug structurally impossible.
#
# Use Gem::Version comparisons instead:
#   Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("4.0.0")
class NoRubyVersionPrefixLintTest < Minitest::Test
  ROOTS = ["lib", "exe", "data"].freeze

  # Forbidden patterns (each is checked against every line in the runtime tree).
  # Comment-only lines are skipped — a comment explaining *why* RUBY_VERSION
  # prefix matching is forbidden is allowed (and welcomed).
  FORBIDDEN = [
    # RUBY_VERSION =~ /^anything/ — the exact legacy bug
    /\bRUBY_VERSION\s*=~\s*/,
    # RUBY_VERSION.start_with?("4") — same intent, different form
    /\bRUBY_VERSION\.start_with\?/,
    # if RUBY_VERSION == "..." — fragile string equality
    /\bif\s+RUBY_VERSION\s*==/,
    # RUBY_VERSION[0..2] / RUBY_VERSION.split(".") — slice-based comparisons
    /\bRUBY_VERSION\s*\[/,
    /\bRUBY_VERSION\.split\(/,
  ].freeze

  def test_no_ruby_version_prefix_comparisons_in_runtime_tree
    violations = []
    ROOTS.each do |root|
      next unless Dir.exist?(root)

      Find.find(root) do |path|
        next unless File.file?(path)
        next unless path.end_with?(".rb", ".yml")

        File.foreach(path).with_index(1) do |line, lineno|
          next if line.lstrip.start_with?("#") # skip comment-only lines

          FORBIDDEN.each do |pattern|
            violations << "#{path}:#{lineno}: #{line.chomp}" if line =~ pattern
          end
        end
      end
    end
    assert_empty violations,
                 "Forbidden RUBY_VERSION prefix-regex comparison(s) found:\n" \
                 "#{violations.join("\n")}\n" \
                 "Use `Gem::Version.new(RUBY_VERSION) >= Gem::Version.new(\"4.0.0\")` instead. " \
                 "See PITFALLS.md §1 / DATA-05."
  end
end
