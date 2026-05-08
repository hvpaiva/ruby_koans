# frozen_string_literal: true

module Rubykoans
  # Immutable per-exercise record. All members are mandatory keyword args
  # (Data.define semantics). See research ARCHITECTURE.md §3.2 and
  # PITFALLS.md §7 for the Data vs Struct rationale.
  #
  # Fields (DATA-02):
  #   name                  String, e.g. "intro1"
  #   dir                   String, e.g. "00_intro"
  #   path                  Pathname (workspace-relative): "exercises/00_intro/intro1.rb"
  #   test?                 Boolean — true for Minitest exercises (Phase 3+)
  #   hints                 Array<String>, ordered, progressive
  #   solution_path         Pathname (workspace-relative): "solutions/00_intro/intro1.rb"
  #   concepts_introduced   Array<String>
  #   concepts_required     Array<String>
  #   skip_check_unsolved?  Boolean — true for intro1 (no broken state)
  Exercise = Data.define(
    :name,
    :dir,
    :path,
    :test?,
    :hints,
    :solution_path,
    :concepts_introduced,
    :concepts_required,
    :skip_check_unsolved?,
  )
end
