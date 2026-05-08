# frozen_string_literal: true

require_relative "lib/rubykoans/version"

Gem::Specification.new do |spec|
  spec.name          = "rubykoans"
  spec.version       = Rubykoans::VERSION
  spec.authors       = ["Highlander Paiva"]
  spec.email         = ["high.v.paiva@gmail.com"]

  spec.summary       = "Modern, Rustlings-inspired Ruby learning gem (working title: Ruby Path)."
  spec.description   = "An exercise-based learning tool for Ruby 4+ that replaces the legacy Edgecase Ruby Koans curriculum with a Rustlings-shaped workspace, a single-subprocess runner, and modern Ruby idioms."
  spec.homepage      = "https://github.com/hvpaiva/rubykoans"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 4.0.0"

  spec.metadata["homepage_uri"]      = spec.homepage
  spec.metadata["source_code_uri"]   = "https://github.com/hvpaiva/rubykoans/tree/master"
  spec.metadata["bug_tracker_uri"]   = "https://github.com/hvpaiva/rubykoans/issues"
  spec.metadata["changelog_uri"]     = "https://github.com/hvpaiva/rubykoans/blob/master/README.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # NOTE: Plan 03 will extend `data/` (info.yml, canonical/, template/) and Plan 04 will
  # add `exe/koans` + `lib/rubykoans/{cli,runner,state,init,solution_writer}.rb`. The glob
  # below already includes those paths so no gemspec edit is needed when they land.
  spec.files = Dir[
    "lib/**/*.rb",
    "lib/**/*.md",
    "lib/**/*.txt",
    "data/**/*",
    "exe/*",
    "rubykoans.gemspec",
    "Gemfile",
    "Gemfile.lock",
    "README.md",
    "LICENSE.txt"
  ]

  spec.bindir        = "exe"
  spec.executables   = ["koans"] # CLI binary; landed by Plan 04 (D-01)
  spec.require_paths = ["lib"]

  # Runtime deps (INFRA-03 — locked: thor, listen, minitest only).
  spec.add_dependency "thor",     "~> 1.5"   # D-10
  spec.add_dependency "listen",   "~> 3.10"  # WATCH-05 spike validates Ruby 4 compat
  spec.add_dependency "minitest", "~> 6.0"   # exercise framework

  # Dev-only — INFRA-03: standardrb is dev-only.
  spec.add_development_dependency "rake",     "~> 13.0"
  spec.add_development_dependency "standard", "~> 1.54"
end
