---
phase: 01-walking-skeleton
plan: 03
subsystem: data
tags: [ruby, yaml, data-define, curriculum, lints, gemspec, pathname, enumerable]

# Dependency graph
requires:
  - phase: 01-walking-skeleton
    provides: "lib/rubykoans.rb base module + Rubykoans::Error, rubykoans.gemspec with data/** glob, test/test_helper.rb wired to Minitest"
provides:
  - "Rubykoans::Exercise (Data.define value object, 9 fields per DATA-02)"
  - "Rubykoans::Curriculum (loads data/info.yml via YAML.safe_load_file with permitted_classes: [Symbol], aliases: false; Enumerable; first/each/size/find_by_name!; gem_data_dir helper)"
  - "Rubykoans::UnsupportedFormatError, Rubykoans::UnknownExerciseError (subclasses of Rubykoans::Error)"
  - "Rubykoans::Colors (stdlib-only ANSI helpers honoring NO_COLOR / RUBYKOANS_NO_COLOR)"
  - "data/info.yml — Phase-1 manifest (1 exercise: intro1)"
  - "data/canonical/00_intro/intro1.rb — post-pass canonical solution"
  - "lib/rubykoans/template/exercises/00_intro/{intro1.rb,README.md} — seed exercise + topic README"
  - "lib/rubykoans/template/solutions/00_intro/intro1.rb — solution stub (DON'T EDIT marker)"
  - "Three CI lints under test/lints/ enforcing DATA-03/04/05"
affects:
  - "01-04 (Runner/Init/SolutionWriter — consumes Curriculum + Exercise + canonical solution + template files)"
  - "Phase 2 (Watcher) — consumes the same Curriculum API and Colors module"
  - "Phase 3+ (real exercises) — extend data/info.yml; the three CI lints make every addition reviewable"

# Tech tracking
tech-stack:
  added:
    - "Ruby Data.define value objects (immutable, keyword-only, value-equality)"
    - "YAML.safe_load_file with explicit permitted_classes allowlist (D-06)"
    - "Pathname-based workspace path representation"
    - "stdlib Find for grep-style code lints"
  patterns:
    - "Two-tier classification by load order: Rubykoans::Error declared in lib/rubykoans.rb BEFORE the per-feature requires so subclasses resolve at load time"
    - "Convention-vs-override for Exercise.path / Exercise.solution_path: derive from dir/name unless info.yml entry provides explicit keys (DATA-02 N6)"
    - "CI-as-curriculum-gate: structural lints under test/lints/ run as part of `rake test` so curriculum drift fails loudly on every PR"
    - "Data ships in the gem via the existing gemspec glob (data/**/*, lib/**/*.md) — no gemspec edit needed when adding new data/template files"
    - "NO_COLOR + RUBYKOANS_NO_COLOR + $stdout.tty? gate for ANSI output (no third-party color gem)"

key-files:
  created:
    - "lib/rubykoans/exercise.rb"
    - "lib/rubykoans/curriculum.rb"
    - "lib/rubykoans/colors.rb"
    - "data/info.yml"
    - "data/canonical/00_intro/intro1.rb"
    - "lib/rubykoans/template/exercises/00_intro/intro1.rb"
    - "lib/rubykoans/template/exercises/00_intro/README.md"
    - "lib/rubykoans/template/solutions/00_intro/intro1.rb"
    - "test/exercise_test.rb"
    - "test/curriculum_test.rb"
    - "test/colors_test.rb"
    - "test/lints/expected_exercise_count_test.rb"
    - "test/lints/concept_ordering_test.rb"
    - "test/lints/no_ruby_version_prefix_test.rb"
  modified:
    - "lib/rubykoans.rb (added Error declaration ordering + 3 require_relative lines)"

key-decisions:
  - "Declare Rubykoans::Error in lib/rubykoans.rb BEFORE require_relative for exercise.rb / curriculum.rb so UnsupportedFormatError + UnknownExerciseError can subclass Rubykoans::Error at load time (load-order fix; not in plan as written)."
  - "test_no_pastel_or_colorize_runtime_dep inspects gemspec.runtime_dependencies directly rather than the global gem environment — `rainbow` is a transitive dev-only dep of `standard` and would otherwise false-positive."
  - "Phrase the canonical solution comment as 'unimplemented-marker line' instead of 'raise NotImplementedError line' so the verify grep `if grep -q 'raise NotImplementedError' data/canonical/...` does not match comment text."
  - "Phase-1 seed entry in data/info.yml relies on convention-based derivation (no explicit `path:` / `solution_path:`) — explicit overrides are reserved for Phase 3+ multi-file exercises."

patterns-established:
  - "Pattern: data/info.yml is the single source of truth for curriculum order (DATA-01). Curriculum.load is the only safe entry point — direct YAML.load is forbidden at the lint level (DATA-05)."
  - "Pattern: Exercise = Data.define(...) — every per-exercise field is mandatory keyword-arg, immutable, value-equal. New exercises just add another entry to info.yml; the data shape is locked."
  - "Pattern: CI structural lints under test/lints/ — run as part of `rake test`; smoke-tested by injecting violations to confirm they fail loudly."
  - "Pattern: data/canonical/<dir>/<name>.rb is the post-pass canonical solution shipped in the gem but consumed only via Plan 04's SolutionWriter.reveal! (PITFALLS.md §4 access boundary). Init never touches data/canonical/ — it walks lib/rubykoans/template/ only. The two trees (lib/rubykoans/template/solutions/ stubs vs data/canonical/ post-pass content) are intentionally split."
  - "Pattern: NO_COLOR + RUBYKOANS_NO_COLOR + $stdout.tty? — three-gate detection used by Rubykoans::Colors. Stdlib-only ANSI helpers; no pastel/colorize/tty-color/rainbow runtime dep."

requirements-completed:
  - DATA-01
  - DATA-02
  - DATA-03
  - DATA-04
  - DATA-05
  - INFRA-05

# Metrics
duration: 15min
completed: 2026-05-08
---

# Phase 01 Plan 03: Curriculum data model + Phase-1 seed exercise + DATA-03/04/05 lints Summary

**Lock the curriculum contract: Rubykoans::Exercise (Data.define) + Rubykoans::Curriculum (YAML.safe_load_file) + data/info.yml seed (intro1) + three CI lints (count, concept ordering, RUBY_VERSION prefix grep) that make legacy PITFALLS.md §1 bug class structurally impossible from day one of Phase 1.**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-05-08T00:27:07Z
- **Completed:** 2026-05-08T00:41:58Z
- **Tasks:** 3
- **Files created:** 14
- **Files modified:** 1

## Accomplishments

- **Data model locked:** `Rubykoans::Exercise` is a 9-field Data.define value object (DATA-02); `Rubykoans::Curriculum` parses `data/info.yml` safely via `YAML.safe_load_file(permitted_classes: [Symbol], aliases: false)` (D-06) and exposes Enumerable + `first`/`each`/`size`/`find_by_name!`/`gem_data_dir`.
- **Seed exercise shipped:** `lib/rubykoans/template/exercises/00_intro/intro1.rb` ships with `raise NotImplementedError` as the D-08 fail state (no `require "minitest/autorun"`, per D-07/D-09); the matching post-pass canonical solution lives at `data/canonical/00_intro/intro1.rb`. Topic README and DON'T-EDIT solution stub also ship.
- **CI structural lints land:** Three lints (`ExpectedExerciseCountLintTest`, `ConceptOrderingLintTest`, `NoRubyVersionPrefixLintTest`) run as part of `bundle exec rake test`; all three were smoke-tested by injecting a violation, confirming a useful failure message, and reverting.
- **INFRA-05 verified end-to-end:** `gem build rubykoans.gemspec && gem unpack` shows `data/info.yml`, `data/canonical/00_intro/intro1.rb`, and the three template paths under `lib/rubykoans/template/` all ship in the published `.gem`.
- **Test count:** 18 runs / 38 assertions / 0 failures / 0 errors / 0 skips. Three new test classes (Exercise, Curriculum, Colors) plus three lint classes.

## Task Commits

Each task was committed atomically:

1. **Task 1: Define Exercise (Data.define), Curriculum, and the seed info.yml** — `92e7052` (feat)
2. **Task 2: Write the seed exercise template, canonical solution, solution stub, topic README, and Colors module** — `db5696c` (feat)
3. **Task 3: Write the three CI lints (DATA-03, DATA-04, DATA-05)** — `f58eecf` (feat)

_Plan metadata commit (this SUMMARY) is created by the orchestrator after worktree merge._

## Files Created/Modified

### Created (14 files)

| File | Lines | Purpose |
|------|-------|---------|
| `lib/rubykoans/exercise.rb` | 29 | `Rubykoans::Exercise = Data.define(...)` — 9 fields per DATA-02. |
| `lib/rubykoans/curriculum.rb` | 127 | `Rubykoans::Curriculum.load` (YAML.safe_load_file), `find_by_name!`, `each`, `size`, error types, gem_data_dir. |
| `lib/rubykoans/colors.rb` | 44 | Stdlib-only ANSI helpers; honors NO_COLOR + RUBYKOANS_NO_COLOR. |
| `data/info.yml` | 37 | Curriculum manifest with format_version: 1 + the intro1 seed. |
| `data/canonical/00_intro/intro1.rb` | 9 | Post-pass canonical solution (no raise line). |
| `lib/rubykoans/template/exercises/00_intro/intro1.rb` | 15 | Seed exercise template with D-08 NotImplementedError fail state. |
| `lib/rubykoans/template/exercises/00_intro/README.md` | 14 | Topic README (DOC-03 deferred convention example). |
| `lib/rubykoans/template/solutions/00_intro/intro1.rb` | 4 | DON'T EDIT solution stub copied by Plan 04 Init. |
| `test/exercise_test.rb` | 43 | Exercise value-object behaviour (3 tests). |
| `test/curriculum_test.rb` | 71 | Curriculum.load + find_by_name! + safe_load discipline (8 tests). |
| `test/colors_test.rb` | 45 | NO_COLOR / RUBYKOANS_NO_COLOR / no color-gem runtime dep (4 tests). |
| `test/lints/expected_exercise_count_test.rb` | 21 | DATA-03 — info.yml entry count vs EXPECTED_EXERCISE_COUNT. |
| `test/lints/concept_ordering_test.rb` | 28 | DATA-04 — concepts_required must be introduced earlier. |
| `test/lints/no_ruby_version_prefix_test.rb` | 55 | DATA-05 — grep-based forbidden-pattern lint over lib/, exe/, data/. |

### Modified (1 file)

| File | Change |
|------|--------|
| `lib/rubykoans.rb` | Moved `Rubykoans::Error` declaration ahead of the new `require_relative` lines (load-order fix); appended requires for `exercise`, `curriculum`, `colors`. |

## Decisions Made

- **Load-order:** `Rubykoans::Error` is declared inline in `lib/rubykoans.rb` BEFORE the `require_relative` lines for `exercise`/`curriculum`/`colors` so the latter can subclass it at load time. The plan's literal text appended the requires before `module Rubykoans`, which would have raised `NameError: uninitialized constant Rubykoans::Error` from `curriculum.rb`.
- **`test_no_pastel_or_colorize_runtime_dep`** inspects the gemspec's `runtime_dependencies` directly rather than the global gem environment. The plan's literal test scanned `Gem::Specification.find_by_name(name)` against the ambient bundle, which finds `rainbow` (transitive dev-only dep brought in by `standard`) and would always fail. The intent ("no color gem in the rubykoans runtime tree") is satisfied by inspecting `spec.runtime_dependencies`.
- **Canonical comment phrasing:** the verify grep `if grep -q 'raise NotImplementedError' data/canonical/00_intro/intro1.rb` matched the original comment text mentioning `raise NotImplementedError`. Rephrased the comment to "the unimplemented-marker line" — content unchanged, lint passes.
- **Phase-1 seed uses convention-based derivation:** no explicit `path:` / `solution_path:` keys in `data/info.yml`. Plan 04 will rely on this convention; explicit overrides are reserved for Phase 3+ exercises with multi-file or non-conventional layouts (see DATA-02 N6).
- **Curriculum is `Enumerable`:** `include Enumerable` + `each` lets the concept-ordering lint do `Rubykoans::Curriculum.load.each do |exercise|`. `to_a`, `map`, `select` all work for free.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed load-order so Rubykoans::Error is declared before subclass requires**
- **Found during:** Task 1 (running `bundle exec rake test` after writing exercise.rb / curriculum.rb).
- **Issue:** The plan's literal text instructs to append `require_relative "rubykoans/exercise"` and `require_relative "rubykoans/curriculum"` BEFORE the existing `module Rubykoans ... class Error ... end` block in `lib/rubykoans.rb`. Loading `curriculum.rb` (which declares `class UnsupportedFormatError < Rubykoans::Error`) before `Rubykoans::Error` is defined raises `NameError: uninitialized constant Rubykoans::Error (NameError)`.
- **Fix:** Restructured `lib/rubykoans.rb` to declare `class Error < StandardError` inside the `module Rubykoans` block FIRST, then `require_relative` the per-feature files AFTER. Updated the file's comment to call out the ordering.
- **Files modified:** `lib/rubykoans.rb`.
- **Verification:** `bundle exec rake test` — 18 runs / 0 failures / 0 errors.
- **Committed in:** `92e7052` (Task 1 commit).

**2. [Rule 1 - Bug] Rewrote `test_no_pastel_or_colorize_dep` to inspect gemspec runtime deps directly**
- **Found during:** Task 2 (initial `bundle exec rake test` after creating `test/colors_test.rb`).
- **Issue:** The plan's literal test scans `Gem::Specification.find_by_name(name)` for each forbidden gem. In a typical dev bundle, `standard` (a dev dep of rubykoans) transitively pulls in `rainbow` (a `rubocop` dep). The test therefore fails on every machine that has `standard` installed — even though `rainbow` is NOT a runtime dep of rubykoans itself.
- **Fix:** Renamed to `test_no_pastel_or_colorize_runtime_dep`. The new body loads `rubykoans.gemspec` via `Gem::Specification.load(...)`, takes `spec.runtime_dependencies.map(&:name)`, and asserts none of `pastel/colorize/tty-color/rainbow` are present. This matches the plan's intent ("no color gem in the rubykoans runtime tree") without false positives from transitive dev deps.
- **Files modified:** `test/colors_test.rb`.
- **Verification:** Test passes; bundle still has `rainbow` (3.1.1) installed transitively but it's correctly NOT flagged.
- **Committed in:** `db5696c` (Task 2 commit).

**3. [Rule 1 - Bug] Rephrased canonical-solution comment to satisfy verify grep**
- **Found during:** Task 2 (running the plan's `verify.automated` block).
- **Issue:** The plan's verify check `if grep -q "raise NotImplementedError" data/canonical/00_intro/intro1.rb` is meant to assert the canonical file does NOT contain the broken `raise` line. The original comment "The fix is to remove the `raise NotImplementedError` line; everything else..." matched the grep, false-positiving the lint.
- **Fix:** Rephrased the comment to "The fix is to delete the unimplemented-marker line shipped in the template; everything else..." — preserves the explanatory content, removes the literal string match.
- **Files modified:** `data/canonical/00_intro/intro1.rb`.
- **Verification:** `grep -q "raise NotImplementedError" data/canonical/00_intro/intro1.rb` exits non-zero (no match).
- **Committed in:** `db5696c` (Task 2 commit).

---

**Total deviations:** 3 auto-fixed (3 × Rule 1 bug)
**Impact on plan:** All three were small mechanical fixes to make the plan's own verify gates self-consistent. No scope creep, no architectural change. The data model, seed exercise, and lints are exactly as the plan describes.

## Issues Encountered

- **Smoke-testing the lints required temporarily mutating tracked files** (info.yml, lib/rubykoans/curriculum.rb, lib/rubykoans.rb). Each mutation was applied, the targeted lint was confirmed to fail with a useful message, and the mutation was reverted via `cp` from a backup. No mutation was committed.
  - `ExpectedExerciseCountLintTest` failed loudly when `EXPECTED_EXERCISE_COUNT` was bumped to 999 — message named the constant, the actual count, and the action ("bump the constant deliberately").
  - `ConceptOrderingLintTest` failed loudly when a fake `bogus_smoke_test` exercise was added with `concepts_required: [unknown_concept]` — message named the exercise, listed the missing concept, and pointed at info.yml.
  - `NoRubyVersionPrefixLintTest` failed loudly when `if RUBY_VERSION == "4.0.0"` was appended to lib/rubykoans.rb — message named the file:line, showed the offending line, and pointed at the `Gem::Version` fix.

## User Setup Required

None — Phase-1 plan 03 has no external service configuration (`user_setup: []` in plan frontmatter).

## INFRA-05 Verification

`gem build rubykoans.gemspec` produces a `.gem` that, when unpacked, contains every file required by Plan 04:

```
/tmp/rk/rubykoans-0.1.0/data/canonical/00_intro/intro1.rb
/tmp/rk/rubykoans-0.1.0/data/info.yml
/tmp/rk/rubykoans-0.1.0/lib/rubykoans/template/exercises/00_intro/README.md
/tmp/rk/rubykoans-0.1.0/lib/rubykoans/template/exercises/00_intro/intro1.rb
/tmp/rk/rubykoans-0.1.0/lib/rubykoans/template/solutions/00_intro/intro1.rb
```

The existing gemspec glob (`Dir["lib/**/*.rb", "lib/**/*.md", "lib/**/*.txt", "data/**/*", ...]` from Plan 01) already covered these paths — no gemspec edit was needed in this plan.

## Next Phase Readiness

- `Rubykoans::Curriculum.load` returns a stable, immutable list of `Rubykoans::Exercise` records. Plan 04's `Init`, `Runner`, `SolutionWriter`, and `CLI` can build against this contract without further data-shape work.
- `data/canonical/00_intro/intro1.rb` is the file Plan 04's `SolutionWriter.reveal!` will copy into the learner workspace after the runner reports a pass on `intro1`. PITFALLS.md §4 access boundary remains Plan 04's responsibility — this plan ships the canonical content at the documented path; nothing in `lib/rubykoans/curriculum.rb` exposes it.
- The three CI lints in `test/lints/` will continue to gate every future PR. Phase 3 exercises must:
  - Bump `Rubykoans::Curriculum::EXPECTED_EXERCISE_COUNT` in `lib/rubykoans/curriculum.rb` together with the new info.yml entries (DATA-03 enforces this);
  - Order new entries so `concepts_required` is a subset of concepts already introduced (DATA-04 enforces this);
  - Continue to avoid `RUBY_VERSION =~ /^.../` and friends — use `Gem::Version` comparisons (DATA-05 enforces this).

## Self-Check: PASSED

- File exists: `lib/rubykoans/exercise.rb` — FOUND
- File exists: `lib/rubykoans/curriculum.rb` — FOUND
- File exists: `lib/rubykoans/colors.rb` — FOUND
- File exists: `data/info.yml` — FOUND
- File exists: `data/canonical/00_intro/intro1.rb` — FOUND
- File exists: `lib/rubykoans/template/exercises/00_intro/intro1.rb` — FOUND
- File exists: `lib/rubykoans/template/exercises/00_intro/README.md` — FOUND
- File exists: `lib/rubykoans/template/solutions/00_intro/intro1.rb` — FOUND
- File exists: `test/exercise_test.rb` — FOUND
- File exists: `test/curriculum_test.rb` — FOUND
- File exists: `test/colors_test.rb` — FOUND
- File exists: `test/lints/expected_exercise_count_test.rb` — FOUND
- File exists: `test/lints/concept_ordering_test.rb` — FOUND
- File exists: `test/lints/no_ruby_version_prefix_test.rb` — FOUND
- Commit `92e7052` — FOUND in git log
- Commit `db5696c` — FOUND in git log
- Commit `f58eecf` — FOUND in git log
- `bundle exec rake test` — 18 runs, 0 failures, 0 errors
- `gem build rubykoans.gemspec` + `gem unpack` — all 5 data/template paths present in the built gem

---
*Phase: 01-walking-skeleton*
*Plan: 03*
*Completed: 2026-05-08*
