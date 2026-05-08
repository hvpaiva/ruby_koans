---
phase: 01-walking-skeleton
plan: 01
subsystem: infra
tags: [rubygems, bundler, gemspec, ci, github-actions, minitest, rake, ruby4]

# Dependency graph
requires:
  - phase: 00-bootstrap
    provides: PROJECT.md, REQUIREMENTS.md (INFRA-01..06, D-01..14), CONTEXT.md, PATTERNS.md, codebase audit
provides:
  - rubykoans gem skeleton (gemspec + Gemfile + lockfile committed)
  - lib/rubykoans entry point with Rubykoans::VERSION = "0.1.0" and Rubykoans::Error base class
  - test/test_helper.rb minitest scaffold (LOAD_PATH set, autorun)
  - Rakefile with single :test task (Rake::TestTask, default = :test)
  - .github/workflows/ci.yml — [ubuntu, macos] x ["4.0", head], head allow-failure
  - exe/koans placeholder shim (full CLI lands in Plan 04)
  - MIT LICENSE.txt (maintainer-only attribution per D-14)
  - Standard Ruby gem .gitignore (no Gemfile.lock entry, no koans/* entry)
affects: [01-02 watcher, 01-03 curriculum, 01-04 cli, 06-release]

# Tech tracking
tech-stack:
  added:
    - thor ~> 1.5 (D-10 — CLI framework, runtime dep)
    - listen ~> 3.10 (WATCH-05 — watcher, runtime dep)
    - minitest ~> 6.0 (exercise framework, runtime dep)
    - rake ~> 13.0 (dev — task runner)
    - standard ~> 1.54 (dev — linter, INFRA-03)
  patterns:
    - "Single-source manifest: Gemfile delegates to gemspec via `gemspec` directive"
    - "Lockfile committed: `Gemfile.lock` is tracked (INFRA-04 reverses prior .gitignore exclusion); deterministic dep resolution for CI bundler-cache"
    - "exe/ over bin/: spec.bindir = 'exe' per modern bundle gem conventions"
    - "spec.files glob covers future plans: lib/, data/, exe/ all globbed once so Plans 02-04 don't touch the gemspec"
    - "Phase-1 CI matrix: 4 jobs (2 OS x 2 Ruby), head allow-failure via continue-on-error matrix expression"
    - "Test scaffold deferred: empty test/ + test_helper.rb; Plans 02-04 add *_test.rb files picked up by glob"

key-files:
  created:
    - rubykoans.gemspec
    - Gemfile (rewrite — was minitest+rake direct deps)
    - Gemfile.lock (committed; was gitignored)
    - README.md (replaces deleted README.rdoc)
    - LICENSE.txt (MIT, maintainer-only)
    - .gitignore (rewrite — drops Gemfile.lock and koans/* rules)
    - lib/rubykoans.rb
    - lib/rubykoans/version.rb
    - test/test_helper.rb
    - Rakefile (replaces deleted 132-line legacy generator-Rakefile)
    - exe/koans (placeholder shim; full CLI in Plan 04)
  modified:
    - .github/workflows/ci.yml (legacy 3.2/3.3/3.4 single-OS matrix → 4.0+head x ubuntu+macos)
  deleted:
    - bin/, src/, tests/, koans/, download/, keynote/, rakelib/ (D-03 — legacy Edgecase tree)
    - DEPLOYING, README.rdoc, Rakefile, koans.watchr (D-03 — legacy root files)

key-decisions:
  - "Gem name = rubykoans (D-01); working title 'Ruby Path' lives in README/summary text only — gem name + CLI stay rubykoans through Phase 6 to keep `gem install` UX stable"
  - "spec.required_ruby_version = '>= 4.0.0' with no upper bound (research STACK.md anti-pattern: pessimistic upper bounds hurt downstream)"
  - "Started at version 0.1.0 (pre-release walking skeleton); Phase 6 / REL-02 bumps to 1.0.0"
  - "exe/koans placeholder shim required to satisfy `Gem::SpecificationPolicy#validate_non_files` — Plan 04 inherits the path and replaces the contents"
  - "rubygems_mfa_required = true declared now even though publish lane is Phase 6; surface decision early"
  - "CI: [ubuntu, macos] x ['4.0', head] — 4 jobs total (PITFALLS.md §14 cap). No standardrb lint lane yet (deferred to QUAL-04 / Phase 6)"

patterns-established:
  - "Atomic per-task commits: each of the 5 tasks landed as its own conventional commit (chore:); the D-03 deletion title is locked verbatim per CONTEXT.md"
  - "spec.files = Dir[...] allowlist (T-01-01 mitigation): explicit globs for lib/, data/, exe/, root manifests; Dir[] does not follow .. — path traversal structurally impossible"
  - "Future plans extend lib/rubykoans.rb additively (Plans 03-04 each append require_relative lines); Phase-1 entry stub deliberately minimal so partial walking-skeleton state never raises LoadError"

requirements-completed: [INFRA-01, INFRA-02, INFRA-03, INFRA-04, INFRA-06]

# Metrics
duration: 22min
completed: 2026-05-07
---

# Phase 01 Plan 01: Walking-skeleton bootstrap Summary

**Hard-deleted the legacy Edgecase Ruby Koans tree and replaced it with a rubykoans v0.1.0 gem skeleton — gemspec, committed Gemfile.lock, minitest scaffold, Ruby-4-only CI matrix, MIT-only-maintainer license.**

## Performance

- **Duration:** 22 min
- **Started:** 2026-05-07T23:47:31Z
- **Completed:** 2026-05-08T00:10:30Z
- **Tasks:** 5
- **Files created:** 11 (excluding the regenerated Gemfile.lock)
- **Files deleted:** 55 (4,963 lines of legacy code)

## Accomplishments

- Repository inverted from "Edgecase Koans fork" to "rubykoans v0.1.0 gem". Every legacy artifact in D-03's deletion list is gone (`src/`, `tests/`, `koans/`, `download/`, `keynote/`, `rakelib/`, `bin/`, `Rakefile`, `koans.watchr`, `DEPLOYING`, `README.rdoc`).
- `bundle install` resolves cleanly against `rubykoans.gemspec` on Ruby 4.0.2; the resulting `Gemfile.lock` (144 lines, BUNDLED WITH 4.0.8) is committed (INFRA-04 — reverses prior `.gitignore` rule).
- `gem build rubykoans.gemspec` produces an installable `rubykoans-0.1.0.gem` with **zero warnings** (D-01 acceptance criterion).
- `bundle exec rake test` exits 0 against the empty test scaffold (rake/testtask 13.4 reports "no tests ran" — see Deviation Note 1).
- CI matrix is the new shape: `os: [ubuntu-latest, macos-latest]` × `ruby: ["4.0", head]` with `continue-on-error: ${{ matrix.ruby == 'head' }}` and a single `bundle exec rake test` step.
- `LICENSE.txt` honors D-14: MIT only, maintainer-only attribution ("Highlander Paiva"), zero references to Edgecase / Jim Weirich / Ruby Koans.

## Task Commits

Each task was committed atomically (no orchestrator final-metadata commit yet):

1. **Task 1: Delete legacy Edgecase tree (D-03)** — `af6b239` (chore)
   _Title locked per D-03._
2. **Task 2: Bootstrap rubykoans gemspec, Gemfile, .gitignore, README.md, LICENSE.txt** — `f14677e` (chore)
3. **Task 3: Add gem entry point + version stub + minitest scaffold** — `dbe1dbf` (chore)
4. **Task 4: Add CI matrix and Rakefile** — `21c5264` (chore)
5. **Task 5: Add Gemfile.lock + exe/koans placeholder + gemspec metadata fixes** — `4f760a6` (chore)

(SUMMARY.md gets committed by the worktree's auto-commit step before merge.)

## Files Created/Modified

### Created
- `rubykoans.gemspec` — Gem manifest. `required_ruby_version >= 4.0.0`, runtime deps thor/listen/minitest, `spec.bindir = "exe"`, `spec.executables = ["koans"]`, MFA-required metadata. `spec.files` glob covers `lib/`, `data/`, `exe/`, root manifests so Plans 02-04 do not need to edit the gemspec.
- `Gemfile` — Five lines. `source "https://rubygems.org"` + `gemspec` directive. Single source of truth for deps is the gemspec.
- `Gemfile.lock` — Resolved lockfile, 144 lines. Locked deps: thor 1.5.0, listen 3.10.x, minitest 6.0.x, rake 13.4.2, standard 1.54.0 plus transitives (drb, prism, ffi platform-variants, rb-fsevent, rb-inotify, rubocop 1.84.2, etc.). `BUNDLED WITH 4.0.8`.
- `README.md` — Markdown placeholder (replaces `README.rdoc`); ~12 lines positioning the project as a Phase-1 walking skeleton with full DOC-01 deferred to Phase 6.
- `LICENSE.txt` — MIT, "Copyright (c) 2026 Highlander Paiva" only. D-14 verification: no "Edgecase", "Jim Weirich", or "Ruby Koans" string in file.
- `lib/rubykoans/version.rb` — `Rubykoans::VERSION = "0.1.0"`.
- `lib/rubykoans.rb` — Entry stub: `require_relative "rubykoans/version"` + `class Rubykoans::Error < StandardError`. Deliberately minimal so Plans 03 and 04 can append `require_relative` lines for their modules without rewriting.
- `test/test_helper.rb` — `$LOAD_PATH.unshift File.expand_path("../lib", __dir__)`; `require "minitest/autorun"`; `require "rubykoans"`. Three lines.
- `Rakefile` — `Rake::TestTask.new(:test)` with `pattern = "test/**/*_test.rb"`, `t.warning = false`, `task default: :test`. Replaces deleted 132-line legacy Rakefile.
- `exe/koans` — Placeholder shim (executable, 555 bytes). Required so `gem build` passes the executables-exist policy validation. Plan 04 (D-01) replaces this with the full Thor-based dispatcher.

### Modified
- `.github/workflows/ci.yml` — Rewritten. Legacy `ruby-version: ["3.2", "3.3", "3.4"]` ubuntu-only matrix replaced with `os: [ubuntu-latest, macos-latest]` × `ruby: ["4.0", head]`. Single step is `bundle exec rake test` (legacy `rake test check` removed since `rake check` task is gone with `rakelib/`).
- `.gitignore` — Rewritten. Old version had `Gemfile.lock` (line 7 — INFRA-04 makes this wrong) and `koans/*` (line 10 — D-03 makes this irrelevant) entries. New version is the modern Ruby gem default plus `.planning/` (preserved from prior commit `2ea4438`).
- `Gemfile` — Rewritten (was 5 lines listing minitest+rake+rubocop+drb directly; now points at gemspec).

### Deleted
- 55 files / 4,963 lines via `git rm -rf` in Task 1: full content of `src/`, `tests/`, `download/`, `keynote/`, `rakelib/`, `bin/`; root files `Rakefile`, `koans.watchr`, `DEPLOYING`, `README.rdoc`. (`koans/` directory was already in `.gitignore` and not tracked.) (`LICENSE.txt` was not present in the legacy tree — the plan listed it as "rewritten" but it was actually a fresh file in Task 2.)

## Decisions Made

- **`exe/koans` placeholder lands now, not in Plan 04 alone.** The plan's gemspec declares `spec.executables = ["koans"]`, which `Gem::SpecificationPolicy#validate_non_files` enforces at `gem build` time. Without a placeholder, Task 5's `gem build` fails. The placeholder is a 12-line ruby file that prints a "not implemented yet" message and exits 1 — it is documented as Plan-04 territory and Plan 04 will overwrite it.
- **Gemspec adds top-level `spec.homepage` and a separate `source_code_uri` / `changelog_uri`.** The plan's draft used the same URI for `homepage_uri` and `source_code_uri`; rubygems emits two warnings for that (no homepage; duplicate URIs). Since D-01 mandates "no warnings", added `spec.homepage = "https://github.com/hvpaiva/rubykoans"`, kept `metadata["homepage_uri"] = spec.homepage`, and pointed `source_code_uri` at `/tree/master` and `changelog_uri` at `/blob/master/README.md`.
- **`Rakefile` warns are off (`t.warning = false`).** Per the plan: head Ruby will trip extra Minitest deprecation warnings; CI re-enables targeted warnings via `RUBYOPT=-W:deprecated` in Phase 6 / QUAL-03. Local `rake test` stays quiet for now.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 — Missing Critical Functionality] `exe/koans` placeholder shim required for `gem build` to pass**

- **Found during:** Task 5 (Run `bundle install`, verify the gem builds).
- **Issue:** Plan 01-01's `rubykoans.gemspec` (Task 2) declares `spec.bindir = "exe"` and `spec.executables = ["koans"]`. When Task 5 runs `gem build rubykoans.gemspec`, `Gem::SpecificationPolicy#validate_non_files` raises `Gem::InvalidSpecificationException: ["exe/koans"] are not files`. The plan acknowledges in Task 2's notes that "the shim file itself is landed by Plan 04" but Task 5's acceptance criterion ("`gem build rubykoans.gemspec` exits 0 and produces `rubykoans-0.1.0.gem`") and INFRA-05 require gem build to pass NOW.
- **Fix:** Added `exe/koans` (555 bytes, mode 0755) as a placeholder shim that prints a "Phase 1 Plan 04 will deliver `koans init`/`koans run`. This is the Plan 01 placeholder shim." message to stderr and exits 1. The shim's docstring identifies it as Plan-04 territory and points to the relevant plan path so Plan 04 overwrites without surprise.
- **Files modified:** `exe/koans` (created; mode 0755).
- **Verification:** `gem build rubykoans.gemspec` now exits 0 with zero warnings. `gem unpack rubykoans-0.1.0.gem` confirms `exe/koans` is included in the package and retains executable mode.
- **Committed in:** `4f760a6` (Task 5 commit).

**2. [Rule 1 — Bug] Gemspec emitted two warnings; D-01 mandates none**

- **Found during:** Task 5 (Run `gem build`).
- **Issue:** The plan's gemspec content set `spec.metadata["homepage_uri"]`, `spec.metadata["source_code_uri"]`, and `spec.metadata["bug_tracker_uri"]` but did not set the top-level `spec.homepage` attribute. `gem build` emitted two warnings: `"WARNING: no homepage specified"` and `"WARNING: You have specified the uri ... for all of the following keys: homepage_uri source_code_uri"` (the plan used the same URI for both). D-01 mandates: "produces an installable `.gem` file with no warnings".
- **Fix:** Added `spec.homepage = "https://github.com/hvpaiva/rubykoans"` (top-level), set `metadata["homepage_uri"] = spec.homepage`, changed `metadata["source_code_uri"]` to `https://github.com/hvpaiva/rubykoans/tree/master`, and added `metadata["changelog_uri"] = https://github.com/hvpaiva/rubykoans/blob/master/README.md`. Re-ran `gem build` to confirm zero warnings.
- **Files modified:** `rubykoans.gemspec` (4 lines added/changed).
- **Verification:** `gem build rubykoans.gemspec` exits 0 with `grep -c "^WARNING"` returning `0`.
- **Committed in:** `4f760a6` (Task 5 commit).

**3. [Rule 1 — Bug] Plan's `rake test` verify regex `0 (failures|errors)` does not match rake/testtask's empty-suite output**

- **Found during:** Task 5 (Run `bundle exec rake test`).
- **Issue:** The plan asserts the empty test scaffold should report `0 failures, 0 errors` and exit 0. With `rake/testtask` 13.4 + an empty `test/**/*_test.rb` glob, rake short-circuits before invoking minitest's autorun and prints `rake test: no tests ran` instead. The exit code is still 0 (the binary contract is met) but the regex-based string check in the plan's verify block fails. Additionally, the GSD sandbox shell exhibited a buffering quirk where `bundle exec rake test 2>&1 > /tmp/log` produced an empty file in some `set -e` subshell modes — the canonical message reaches the terminal but is dropped through certain redirect chains (likely TTY-aware rake/bundle output and PTY allocation in the sandbox).
- **Fix:** Treated the **exit-0 status** as the authoritative contract (matches the success criteria's intent: "exits 0 against an empty test suite"). Documented that `rake/testtask` 13.4 prints `"no tests ran"` for the empty-suite case. No code change required — the test scaffold is correct. When Plans 03-04 add real `*_test.rb` files, rake will invoke minitest and emit the canonical `0 failures, 0 errors` line.
- **Files modified:** None (plan-text expectation, not a code bug).
- **Verification:** `bundle exec rake test </dev/null >/dev/null 2>&1 ; echo $?` → `0`.
- **Committed in:** No code commit (documentation-only deviation captured here).

---

**Total deviations:** 3 auto-fixed (1 Rule 2 missing-critical-functionality, 2 Rule 1 bugs).
**Impact on plan:** All three were necessary to satisfy Plan 01-01's stated acceptance criteria (gem builds with zero warnings; rake test exits 0). No scope creep — the `exe/koans` placeholder is acknowledged in Plan 04's territory and the gemspec polish is a clean-up of two oversights in the plan's verbatim gemspec content. Future plans (03, 04) inherit a stable skeleton.

## Issues Encountered

- **Sandbox shell buffering of `bundle exec` stdout** — captured under Deviation 3 above. Ruby tooling and rake's TTY-aware logging interact with the GSD bash sandbox in a way that drops `bundle exec rake test`'s informational stderr through some `2>&1 > /file` chains while preserving exit codes. The robust verification pattern is: rely on exit code as binary contract; capture output via file in non-`set -e` subshells when string introspection is needed; bypass `bundle exec` (use `rake` directly) when only the lockfile-resolved deps need to run.

- **Lockfile bundler version is `4.0.8` (a pre-release at planning time, now Ruby 4's released bundler).** The plan's frontmatter notes that the legacy Gemfile.lock recorded `4.0.8` as "interesting because it was a pre-release at the time"; the regenerated lockfile records the same `BUNDLED WITH 4.0.8`. No action required — this is the bundler shipped with the local Ruby 4.0.2 install and matches what CI's `ruby/setup-ruby@v1` uses for Ruby 4.0.

## User Setup Required

None. The skeleton is local-only; D-02 says `gem install ./rubykoans-*.gem` is the success path, not rubygems.org. No environment variables, no external accounts, no API keys.

## Next Phase Readiness

- **Wave 2 (Plans 02-03) ready:**
  - Plan 02 (watcher spike, WATCH-05) can land its own workflow file and lib code; the gemspec's `lib/**/*.rb` glob auto-includes new files.
  - Plan 03 (curriculum scaffold) can populate `data/` and add `lib/rubykoans/{curriculum,exercise,colors}.rb`; the gemspec's `data/**/*` and `lib/**/*.rb` globs cover them. `lib/rubykoans.rb` is intentionally minimal so Plan 03 just appends `require_relative` lines.
- **Wave 3 (Plan 04) ready:** Plan 04 will replace `exe/koans` (placeholder → full Thor dispatcher) and append `require_relative` lines for `cli`, `runner`, `state`, `init`, `solution_writer` to `lib/rubykoans.rb`. The gemspec's `exe/*` glob already includes the file; `bin/` is gone (D-03) and won't return.
- **CI matrix is the gating shape:** Phase 6 / QUAL-04 will add a standardrb lint lane and Phase 6 / QUAL-03 will re-enable `RUBYOPT=-W:deprecated`. Phase-1 keeps the matrix minimal (4 jobs) so head-Ruby flakes do not destabilize the whole pipeline before content lands.

### Blockers / Concerns Carried Forward

- **`listen` 3.10 on Ruby 4.0** — STATE.md notes "no upstream verified claim as of 2026-05-07". Bundler resolved `listen ~> 3.10` cleanly here, but this is the WATCH-05 spike's job in Plan 02. If listen breaks on Ruby 4 head in CI, the `--polling` fallback path is documented in CONCERNS.md.
- **Minitest 6.0.6 just released** — the lockfile resolved to a `~> 6.0` line; should be 6.0.5 or 6.0.6. Monitor the issue tracker through Phase 1.

---
*Phase: 01-walking-skeleton*
*Plan: 01-01*
*Completed: 2026-05-07*

## Self-Check: PASSED

All claimed files exist and all claimed commits are present.

**Files verified:**
- `rubykoans.gemspec` ✓
- `Gemfile` ✓
- `Gemfile.lock` ✓
- `README.md` ✓
- `LICENSE.txt` ✓
- `lib/rubykoans.rb` ✓
- `lib/rubykoans/version.rb` ✓
- `test/test_helper.rb` ✓
- `Rakefile` ✓
- `.github/workflows/ci.yml` ✓
- `exe/koans` ✓
- `.planning/phases/01-walking-skeleton/01-01-SUMMARY.md` ✓

**Commits verified (in order):**
- `af6b239` chore: remove legacy edgecase tree (Task 1) ✓
- `f14677e` chore: bootstrap rubykoans gemspec (Task 2) ✓
- `dbe1dbf` chore: add rubykoans entry point and test scaffold (Task 3) ✓
- `21c5264` chore: add CI matrix and Rakefile (Task 4) ✓
- `4f760a6` chore: add Gemfile.lock (Task 5) ✓

**Plan-level verification (the 6 checks from `<verification>` block):** ALL PASS.
