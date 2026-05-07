# Codebase Concerns

**Analysis Date:** 2026-05-07

> **Strategic context:** An untracked design memo, `ruby-koans-overhaul-context.md`, sits at the repo root and outlines a planned full overhaul: modernize content for Ruby 3+/4, replace the assertion-filling didactic with a Rustlings-style "edit code under test" model, and rebuild the infrastructure (CLI, watcher, runner, exercise/solution split). Most concerns below should be read as drivers for that overhaul, not just isolated bugs.

## Tech Debt

### Legacy `Neo` mini-framework instead of a real test framework

- Issue: The koans run on a hand-rolled mini-framework (`Neo::Koan`, `Neo::Sensei`, `Neo::ThePath`, `Neo::Assertions`) that imitates Test::Unit from the Ruby 1.8 era. `Gemfile` already declares `minitest` (`Gemfile:3`) and `Gemfile.lock` resolves Minitest 6.0.2, but Minitest is only used by the project's own internal tests under `tests/`. The actual learner-facing runner ignores it.
- Files: `src/neo.rb:1-563`, `koans/neo.rb` (identical copy), `Gemfile:3`, `Gemfile.lock:5-8`.
- Impact: Learners never see `bundle exec`, `rake test`, Minitest, or RSpec — i.e., none of the real Ruby testing toolchain. The runner also swallows `StandardError` and `Neo::Sensei::FailedAssertionError` in `Koan#meditate` (`src/neo.rb:463-477`) and packages errors into a custom "Sensei" UI, which hides authentic interpreter output. Replacing this is one of the three explicit overhaul goals in `ruby-koans-overhaul-context.md` (Frente 3 — Infraestrutura).
- Fix approach: Reimplement the runner on Minitest (or RSpec) using a normal `lib/` + `test/` (or `spec/`) split. Delegate progress, color, and ordering to a thin layer on top of standard Minitest reporters. Remove `src/neo.rb` after migration.

### Dual code path: legacy Rakefile flow vs. new `bin/koans` CLI

- Issue: There are now two parallel entry points for "walk the path": the original Rake-based flow (`rake walk_the_path` → `cd koans && ruby path_to_enlightenment.rb`) and the recently-added CLI in `bin/koans`. They duplicate the koan-generation logic, which is a real maintenance trap.
- Files: `Rakefile:60-67` (defines `:walk_the_path` and reimplements the run pipeline), `Rakefile:24-55` (`Koans.remove_solution`, `Koans.make_koan_file`), `bin/koans:329-354` (duplicate `make_koan_file` and `remove_solution`), `Rakefile:73-75` (`rake watch` shells out to `bin/koans watch`, so Rake now depends on the CLI), `bin/koans:155-157` (`generate_koans` shells out to `rake gen`, so the CLI depends on Rake). The two layers call into each other instead of sharing a single module.
- Impact: Any change to solution-stripping rules (e.g. for the planned Ruby 4 modernization) must be applied in two unrelated regexes. The README also documents both flows as canonical (`README.rdoc:14-86`), reinforcing the duplication.
- Fix approach: Extract solution stripping and koan-file generation into a single Ruby module under `lib/` and have both `Rakefile` and `bin/koans` require it. Long-term, deprecate the Rake entry point in favor of the CLI, since the overhaul plan favors a Rustlings-style CLI.

### `koans/` directory checked into git despite being a generated artifact

- Issue: `.gitignore` line 10 says `koans/*`, marking the entire generated tree as ignored, but the working copy contains a fully populated `koans/` directory (40 files including `koans/.path_progress`, `koans/README.rdoc`, `koans/triangle.rb`, etc.) and the `git log -- bin/koans` shows past commits touching that path.
- Files: `.gitignore:10`, `koans/` (whole directory), `Rakefile:99-116` (regen task), `bin/koans:155-157` (CLI assumes `rake gen` produces it).
- Impact: Confusing onboarding: a fresh clone may or may not already have `koans/` populated depending on history. The `.path_progress` artifact (`koans/.path_progress`) and `koans/README.rdoc` (a copy of the root `README.rdoc` produced by `Rakefile:108-110`) can drift silently. The `download/rubykoans.zip` build target depends on `koans/*` existing (`Rakefile:87-89`).
- Fix approach: Pick a side. Either (a) treat `koans/` as a true build artifact, ensure it is excluded by `.gitignore` and produced on demand by `rake gen` / `bin/koans walk`, and remove any tracked copies from git history going forward; or (b) remove the `koans/*` line from `.gitignore` and check the generated tree in. The overhaul plan implicitly assumes option (a) (separate exercises from "solutions").

### Legacy distribution targets (`download/`, `keynote/`, `DEPLOYING`) are stale

- Issue: `DEPLOYING` (`DEPLOYING:1-12`) describes uploading `download/rubykoans.zip` to a personal Linode box hosting `onestepback.org`, which has nothing to do with the current fork. `Rakefile:80-97` still defines `:zip`, `:package`, and `:upload` targets that `scp` to that host. `keynote/RubyKoans.key` is a 380 KB binary Apple Keynote slide deck last touched in 2011 (`git log` of `keynote/`).
- Files: `DEPLOYING:1-12`, `Rakefile:80-97`, `download/rubykoans.zip` (40 KB), `keynote/RubyKoans.key` (380 KB).
- Impact: Dead code paths (`rake upload`, `rake package`) pointing at infrastructure the current owner does not control. The binary `keynote/RubyKoans.key` bloats the repo and has no editable source. Both are flagged as suspect in the user's overhaul memo.
- Fix approach: Delete `DEPLOYING`, `download/`, and `keynote/` (or move `keynote/` to a separate "history" archive). Drop the `:zip`, `:package`, `:upload`, `:clobber_zip` Rake tasks and the corresponding constants `DOWNLOAD_DIR` / `ZIP_FILE` (`Rakefile:6-13`). Replace with a real distribution channel (a gem, a `cargo install rustlings`-style installer, or simply `git clone`).

### `README.rdoc` still in RDoc format

- Issue: Top-level documentation is `README.rdoc`, which uses RDoc markup (`=`, `+code+`, `::`). GitHub renders RDoc, but every modern Ruby project uses Markdown, and the overhaul memo highlights modernization across the board.
- Files: `README.rdoc:1-140`, `Rakefile:108-110` (copies it into `koans/`).
- Impact: Friction for contributors editing docs; inconsistent with current Ruby community defaults; auto-generation into `koans/` propagates the format.
- Fix approach: Convert to `README.md`. Update `Rakefile:108-110` (and `bin/koans` if it ever references it) to copy the new file. Delete `koans/README.rdoc` from the generated tree.

### Bundler version pinned to a non-existent release

- Issue: `Gemfile.lock:25-26` records `BUNDLED WITH 4.0.8`. Bundler 4.x has not been released; the highest stable line as of early 2026 is 2.x. This was almost certainly hand-edited or generated by a pre-release/dev build.
- Files: `Gemfile.lock:26`.
- Impact: `bundle install` on a fresh machine will warn or refuse depending on the installed Bundler. CI (`.github/workflows/ci.yml:18-21`) uses `ruby/setup-ruby@v1` with `bundler-cache: true`, which selects Bundler from the lockfile and may fail on this value.
- Fix approach: Regenerate `Gemfile.lock` with the Bundler version actually targeted (e.g. 2.5.x) by running `bundle lock --update --bundler`. Pin the version explicitly in CI if reproducibility matters.

## Known Bugs

### Watcher loop has no error handling and depends on `system 'clear'`

- Symptoms: `bin/koans watch` (`bin/koans:49-70`) loops forever calling `walk_without_regenerating`. There is no `rescue` around the body; any unexpected exception in `watched_files_signature` (e.g. a koan file deleted mid-loop, file with non-utf8 path) crashes the watcher with a stack trace. `clear_screen` (`bin/koans:181-183`) shells out to `system("clear")`, which silently no-ops on Windows or in non-tty pipelines.
- Files: `bin/koans:49-70`, `bin/koans:181-183`, `bin/koans:185-190`.
- Trigger: Save a file fast enough to race with `File.stat`, or run on Windows without a `clear` binary.
- Workaround: Set `KOANS_NO_CLEAR=1` (`bin/koans:182`) and rely on terminal scrollback.

### Legacy `koans.watchr` script duplicated and uses raw `system` calls

- Symptoms: There are two watcher scripts: `koans.watchr` at the repo root (`koans.watchr:1-11`) and `src/koans.watchr` (`src/koans.watchr:1-11`). The root one runs `ruby bin/koans walk`; the one inside `src/` runs `ruby ../bin/koans walk` (i.e. assumes a different cwd). Neither uses Bundler. Both were obsoleted by `bin/koans watch`.
- Files: `koans.watchr:1-11`, `src/koans.watchr:1-11`.
- Trigger: Anyone following the original Ruby Koans documentation will install the abandoned `watchr` gem, run `watchr koans.watchr`, and bypass the new CLI's logic entirely.
- Workaround: Use `bin/koans watch` instead.
- Fix approach: Delete both `koans.watchr` files now that `bin/koans watch` exists. Update README accordingly.

### `Sensei#instruct` writes `.path_progress` in the cwd, not in `koans/`

- Symptoms: `Neo::Sensei` uses the bare constant `PROGRESS_FILE_NAME = '.path_progress'` (`src/neo.rb:217`) and opens it with no path prefix (`src/neo.rb:222`, `src/neo.rb:230`). The Rake-based flow `cd`s into `koans/` first (`Rakefile:62-66`), so it lands there. The CLI's `walk` also `cd`s into `KOANS_DIR` via `run` (`bin/koans:163-169`), so it also lands there in the normal flow. But anything that loads `neo.rb` from a different directory (e.g. `tests/neo_output_test.rb:4` which `require_relative "../src/neo"`) will create a `.path_progress` wherever it is invoked.
- Files: `src/neo.rb:217-238`, `tests/neo_output_test.rb:1-5`.
- Trigger: Run any test that loads `neo.rb` from a non-`koans/` cwd.
- Workaround: `tests/neo_output_test.rb` sets `ENV['NEO_DISABLE_END'] = 'true'` (`tests/neo_output_test.rb:3`) which avoids the runner's `END {}` block, but does not stop the file from being created if `add_progress` is invoked.
- Fix approach: Make the path explicit (constructor arg or `ENV['KOANS_PROGRESS_FILE']` like the CLI uses at `bin/koans:197`) and pass it from `ThePath#walk`. The CLI already knows the right path (`bin/koans:13`) — share that constant.

### `Neo::Sensei#show_progress` divides by zero when no koans are loaded

- Symptoms: `show_progress` computes `pass_count*100/total_tests` (`src/neo.rb:291`) without guarding against `Neo::Koan.total_tests == 0`. If `path_to_enlightenment.rb` is mis-required or all version gates skip every file, the runner crashes with `ZeroDivisionError` after the user's first failure.
- Files: `src/neo.rb:277-293`.
- Trigger: Run on a Ruby version where every `in_ruby_version` gate excludes its file (currently impossible because `path_to_enlightenment.rb` includes ungated files, but a regression in the version gates would expose it).
- Fix approach: Guard `total_tests > 0` and bail out with a clear "no koans loaded" message before computing the bar.

### `ruby_version?` matches by string prefix, not semver

- Symptoms: `ruby_version?` does `RUBY_VERSION =~ /^#{version}/` (`src/neo.rb:18-22`). Calling `in_ruby_version("2", "3", "4")` (`src/path_to_enlightenment.rb:15`) on Ruby `3.10.x` would not match `"3"` if the major-minor were `"31"`. Calling it on Ruby `3.0.x` (`"3.0"`) matches `"3"` only because of the literal regex `^3`. There is no actual semver comparison except in `before_ruby_version` (`src/neo.rb:28-30`).
- Files: `src/neo.rb:18-30`, `src/path_to_enlightenment.rb:15`, `src/path_to_enlightenment.rb:38-43`.
- Trigger: Future Ruby versions whose `RUBY_VERSION` does not start with one of the listed prefixes (e.g. `4.0.0` would match `"4"` correctly, but `"4.10.0"` is fine, while `"40.x"` if someone writes it would be wrong).
- Fix approach: Replace the prefix regex with `Gem::Version` comparisons everywhere, or with a small `RubyVersion` matcher. Combine `in_ruby_version` and `before_ruby_version` into one helper.

## Security Considerations

### `bin/koans reset` accepts a user-supplied filename and writes into `koans/`

- Risk: Path traversal / arbitrary file write under `KOANS_DIR`.
- Files: `bin/koans:126-153`, `bin/koans:320-327`.
- Current mitigation: `normalize_target_file` (`bin/koans:320-327`) strips a leading `src/` or `koans/`, appends `.rb` if no extension, and rejects names that do not match `\A[\w.\-]+\z`. The `.\-` are inside a character class so a literal `..` cannot pass.
- Recommendations: The current regex is reasonable, but the destination is built with `File.join(KOANS_DIR, file)` (`bin/koans:139`) without `File.expand_path` + prefix check. Add an explicit `File.expand_path(destination).start_with?(File.expand_path(KOANS_DIR) + File::SEPARATOR)` assertion before writing. This is defense-in-depth in case the regex is loosened later.

### `koans.watchr` runs `system 'clear'` and `system 'ruby ...'` without bundle context

- Risk: Both watcher scripts (`koans.watchr:2-3`, `src/koans.watchr:2-3`) invoke a bare `ruby` from `PATH`, bypassing `bundle exec`. If a learner has multiple Ruby versions, they may execute the koans against an unrelated interpreter.
- Files: `koans.watchr:1-11`, `src/koans.watchr:1-11`.
- Current mitigation: None. `RbConfig.ruby` is used inside `bin/koans` (`bin/koans:171-173`), but the watchr scripts don't.
- Recommendations: Delete the watchr scripts (see Known Bugs above). If kept, route them through `bin/koans` and rely on the CLI's `RbConfig.ruby`.

### `eval` in koan content

- Risk: `src/about_methods.rb:22, 25` and `src/about_classes.rb:37, 53` use `eval` in test bodies (this is intentional for teaching, not a bug). However, the comment `# REMOVE CHECK # __` and `# ENABLE CHECK # __` on lines `src/about_methods.rb:22, 25` are processed by `Rakefile:30` which strips trailing `# __`, so the visible learner version is `eval "assert_equal 5, my_global_method(2, 3)"` and `eval "assert_equal 5, my_global_method 2, 3"`.
- Current mitigation: Inputs are static literals controlled by the koan file, not user input. Learners running koans on their own machine are the only ones affected.
- Recommendations: Keep `eval` (it is pedagogical), but document it explicitly and consider replacing with `instance_eval` or comment-only demonstrations in the overhaul.

## Performance Bottlenecks

### Watcher polls every 0.5 s by stat'ing every koan file

- Problem: `bin/koans watch` (`bin/koans:49-70`, `bin/koans:185-190`) sleeps 0.5 s, then `Dir`-globs `koans/*.{rb,txt}`, calls `File.stat` on each, builds an array of `[path, mtime, size]`, and string-compares the whole signature. With ~40 files this is fine, but it consumes CPU on idle and causes a half-second feedback delay.
- Files: `bin/koans:49-70`, `bin/koans:185-190`.
- Cause: No fs-event integration (no `listen` gem, no `inotify`, no `fswatch`).
- Improvement path: Use the `listen` gem or `rb-inotify`/`rb-fsevent` for proper FS notifications. This also lets the CLI run sub-process-per-change with confidence.

### `koan_steps` loads the full path on every CLI invocation that needs it

- Problem: `bin/koans list`, `bin/koans next`, `bin/koans hint` all call `koan_steps` (`bin/koans:206-219`), which `load`s `path_to_enlightenment.rb` (`bin/koans:221-227`). That in turn requires every `about_*.rb` file (~40), defines all classes, and inspects `Neo::Koan.subclasses`. Each invocation pays the full load cost (~hundreds of ms) just to print a list.
- Files: `bin/koans:206-249`.
- Cause: No caching; the CLI process is short-lived but does not memoize between invocations.
- Improvement path: Acceptable for now. If perceived latency becomes an issue, persist a cached manifest (`koans/.koan_index`) generated at `rake gen` time and read by the CLI.

## Fragile Areas

### Solution-stripping regex is duplicated and brittle

- Files: `Rakefile:24-32`, `bin/koans:347-354`. Both define near-identical regex pairs to strip `__(...)`, `___(...)`, `____(...)`, `_n_(...)`, `/\#{__}/`, and trailing `# __`. They drift the moment one is updated.
- Why fragile: Subtle mismatches (e.g. one accepts a space before `# __`, the other does not) silently change the generated koans. There is no shared specification, no tests directly covering the regex behavior on edge cases (e.g. `__("hello (world)")` — the regex `\b__\([^\)]+\)` stops at the first `)`).
- Safe modification: Always change both files together, then `rake regen` and diff `koans/` against the previous generated tree.
- Test coverage: `tests/check_test.rb` only verifies that no `assert*` lines lack a `__`/`_n_` token (`rakelib/checks.rake:18-44`). It does not test the regex itself.

### `Neo::Koan.method_added` registers every method as a test if it matches `/^test_/`

- Files: `src/neo.rb:485-487`, `src/neo.rb:524-526`.
- Why fragile: Any helper method on a `Neo::Koan` subclass that accidentally starts with `test_` becomes part of the suite. This is a 2009-era convention that predates Minitest's explicit `def test_*` discovery via `public_instance_methods`.
- Safe modification: When adding helpers, prefix them with anything other than `test_`.
- Test coverage: None. The check task (`rakelib/checks.rake:18-44`) does not catch this.

### Pattern-matching koans are gated, but the file relies on Ruby 3 syntax even when read

- Files: `src/path_to_enlightenment.rb:41-43`, `src/about_pattern_matching.rb:1-215`.
- Why fragile: The `require 'about_pattern_matching'` is wrapped in `in_ruby_version("2.7", "3", "4")`, so older Ruby never `require`s the file. But any tooling that statically loads or parses the file (e.g. RuboCop, `ripper`, the upcoming "list all koans" feature in `bin/koans:206-219` which does load `path_to_enlightenment.rb`) will still parse it once Ruby loads the file. On Ruby <2.7, `case ... in` (`src/about_pattern_matching.rb:7-12`) is a syntax error at parse time, so the file cannot be merely required-and-skipped — the gate works because `require` is what the gate guards.
- Why this matters now: The user's overhaul memo specifically calls out that `about_pattern_matching.rb` predates Ruby 3 polish. Notable issues inside the file:
  - `test_variable_pattern_with_binding` (`src/about_pattern_matching.rb:53-64`): the so-called "variable pattern" `case 0; in variable; ... end` actually performs an **assignment** that pins to `variable` and is widely considered confusing. This deserves a clearer pedagogical treatment in modern Ruby.
  - `test_alternative_pattern` (`src/about_pattern_matching.rb:105-119`) and `test_array_pattern` (`src/about_pattern_matching.rb:156-168`) are correct but never demonstrate find-pattern (`[*, x, *]`) which has been stable since 3.0.
  - `LetterAccountant#deconstruct_keys` (`src/about_pattern_matching.rb:175-184`) ignores `nil` keys (Ruby 3.1+ allows `keys` to be nil).
- Safe modification: Touch the file only with Ruby ≥ 3.0 in scope. Keep the `require` gate.
- Test coverage: None of the project's own tests exercise pattern-matching koans.

### `tests/check_test.rb` invokes Rake tasks that assume cwd at repo root

- Files: `tests/check_test.rb:1-26`, `tests/test_helper.rb:1-5`.
- Why fragile: `Rake.application.load_rakefile` (`tests/test_helper.rb:5`) is called once per process. Re-loading or running tests from a different cwd will fail. `Rake::Task['check:asserts'].invoke` (`tests/check_test.rb:16, 22`) relies on `Dir['src/about_*.rb']` (`rakelib/checks.rake:5, 23`), so the check tasks silently report 0 files if cwd is wrong.
- Safe modification: Always run `rake test` from the repo root.
- Test coverage: Self-referential — these tests test the checks.

### `Neo::Sensei#progress` reads `@_contents` but the cached value is reset on every `add_progress`

- Files: `src/neo.rb:217-238`.
- Why fragile: `add_progress` sets `@_contents = nil` (`src/neo.rb:220`) so the next call to `progress` re-reads the file. But `progress.last.to_i` is called inline in `observe` (`src/neo.rb:244`), `instruct` (`src/neo.rb:272`), and `encourage` (`src/neo.rb:357`). Each call hits the disk if `add_progress` ran in between. With ~280 koan steps and a fail-fast model this is fine, but the implicit cache invalidation is non-obvious.
- Safe modification: Treat `@_contents` as private; do not call `progress` from new code paths without thinking about staleness.

## Modernization Gaps

### Ruby 1.8/1.9-era code paths still in `neo.rb`

- Issue: `src/neo.rb` still contains:
  - `require 'win32console'` rescue (`src/neo.rb:6-9`) — Windows console color hack obsoleted by Windows 10 ANSI support and never relevant to JRuby/macOS/Linux.
  - `KeyError` polyfill for Ruby 1.8 (`src/neo.rb:32-35`) — Ruby has had `KeyError` since 1.9.
  - `if RUBY_VERSION < "1.9"` branches in `__`, `_n_`, `___` (`src/neo.rb:39-63`) — the 1.9 fork is dead code on every supported runtime (CI matrix is 3.2/3.3/3.4 per `.github/workflows/ci.yml:11`).
  - `in_ruby_version("1.9", "2", "3") { public :method_missing }` (`src/neo.rb:73-75`) — `method_missing` has been private since 1.9 and is still private in 4; the public override is fine but the gate excludes any future Ruby major.
  - `using_win32console` / `using_windows?` color logic (`src/neo.rb:138-144`) — uses `File::ALT_SEPARATOR` as a Windows detector, which is brittle.
- Files: `src/neo.rb:6-9`, `src/neo.rb:32-35`, `src/neo.rb:39-63`, `src/neo.rb:73-75`, `src/neo.rb:138-144`.
- Recommendations: Drop all 1.8/1.9 branches. Drop `win32console`. Drop the `KeyError` polyfill. Treat Ruby 3.2 as the floor.

### Ruby 1.8/1.9 era teaching content in koan files

- Issue: Several `about_*.rb` files still contain `in_ruby_version("1.8") do ... end` and `in_ruby_version("1.9", "2", "3") do ... end` blocks teaching the difference between two long-dead Rubies. They never execute on the supported CI matrix but still confuse readers.
- Files: `src/about_iteration.rb:11-21` (`as_name` shim for symbols-as-strings), `src/about_strings.rb:153-167` (single-character literal `?a` as integer vs. string), `src/about_symbols.rb:36-43` (`in_ruby_version("mri")` block for `Symbol.all_symbols`).
- Recommendations: Delete the 1.8 branches and the dual `in_ruby_version` shims. Inline the modern behavior.

### `about_methods.rb` still gates a koan on Ruby <2.7

- Issue: `if before_ruby_version("2.7")` (`src/about_methods.rb:130-137`) hides a koan that demonstrates `NoMethodError` on private methods called with explicit receivers. The behavior changed in 2.7 (you can call `self.private_method` since 2.7), so the koan is correct to gate, but on the supported CI matrix (3.2+) the koan never runs and the underlying lesson is lost.
- Files: `src/about_methods.rb:130-137`.
- Recommendations: Replace with a Ruby-3-aware koan that teaches the new (correct) behavior of `self.private_method`.

### `about_keyword_arguments.rb` does not cover Ruby 3 separation of positional and keyword args

- Issue: `src/about_keyword_arguments.rb:1-43` demonstrates basic keyword args and "wrong number of arguments" errors but says nothing about the Ruby 3.0 hard separation, `**` double-splat, `**nil` to forbid keywords, or `...` argument forwarding (Ruby 2.7+, fully supported in 3.x).
- Files: `src/about_keyword_arguments.rb:1-43`.
- Recommendations: Add koans for `**`, `**nil`, `...`, and the 2.7→3.0 separation. Mentioned as "Frente 1 — Modernização do conteúdo" in `ruby-koans-overhaul-context.md`.

### No coverage of modern Ruby features

- Gaps (none of these have a koan):
  - `Data.define` (Ruby 3.2+) — value objects.
  - `Ractor` (3.0+) — concurrency model.
  - `Fiber.scheduler` / non-blocking IO (3.0+).
  - Endless method definitions (`def foo = ...`) (3.0+).
  - Numbered block parameters `_1`, `_2` (2.7+) and the `it` block parameter (3.4+).
  - `Hash#except`, `Array#intersect?` (3.0+/3.1+).
  - Pattern matching's find-pattern, `Hash#deconstruct_keys` with `nil` keys, `=>` rightward assignment.
  - Frozen string literals — none of the source files use the `# frozen_string_literal: true` magic comment except `bin/koans:2`.
- Recommendations: New koan files for each major modern feature. Drive the order from `path_to_enlightenment.rb` and the overhaul memo.

### `about_java_interop.rb` is dead weight on CRuby

- Issue: `src/about_java_interop.rb:1-138` is gated to `in_ruby_version("jruby")` only (`src/path_to_enlightenment.rb:38-40`), and the project's CI (`.github/workflows/ci.yml:11`) only runs CRuby 3.2/3.3/3.4. JRuby is not tested.
- Files: `src/about_java_interop.rb`, `koans/about_java_interop.rb`, `src/path_to_enlightenment.rb:38-40`.
- Recommendations: Either remove the JRuby koans entirely (the overhaul plan reframes the project around modern CRuby) or add JRuby to the CI matrix and treat them as first-class. Currently they are unmaintained.

### `about_extra_credit.rb` is a 9-line comment, not an exercise

- Issue: `src/about_extra_credit.rb:1-9` is just a comment block telling the user to "Create a program that will play the Greed Game" with no scaffolding, no tests, and no acceptance criteria. The overhaul memo calls this out specifically as "vida que segue".
- Files: `src/about_extra_credit.rb:1-9`, `koans/about_extra_credit.rb:1-9`.
- Recommendations: Either remove and replace with a proper Rustlings-style multi-file exercise (with a real `lib/`, `test/` and runner integration) or excise and treat the project's final lesson as the proxy/dice projects.

## Scaling Limits

### Single ordered path — no chapters, no skipping, no parallelism

- Current capacity: ~280 koan steps in a single linear sequence (`src/path_to_enlightenment.rb:1-45`). The runner stops at the first failure and the progress file stores a single integer (`src/neo.rb:217-225`).
- Limit: The pedagogical model assumes a single ordering forever. There is no notion of "I am studying iteration today, skip strings."
- Scaling path: The Rustlings-style overhaul implies grouping exercises by topic (chapters) with optional ordering, watch-only-this-file, and per-chapter progress. `bin/koans list` (`bin/koans:72-88`, `bin/koans:250-279`) already groups by file in its output, so the data model is partially there.

### Progress file is a CSV with no schema

- Current capacity: `koans/.path_progress` is a flat comma-separated list of pass counts (`koans/.path_progress` content: `0,0,0,0,0,0,0,0`). The CLI parses it as `File.read(progress_file).gsub(/\s/, '').split(',').last.to_i` (`bin/koans:200-204`).
- Limit: No timestamps, no per-file progress, no completion records, no streak detection beyond `Neo::Sensei#encourage` (`src/neo.rb:349-360`).
- Scaling path: Move to a small JSON or YAML file with a real schema (per-file completion timestamps, last failure, streak). Bump the schema version explicitly.

## Dependencies at Risk

### `minitest 6.0.2` resolves only because of `prism` and `drb` recent versions

- Risk: Minitest 6.x is a major version bump from the long-stable 5.x. Many tutorials, RubyGems, and Rails LTS branches still target 5.x. Pinning to 6.x in a learning project may surprise users.
- Files: `Gemfile.lock:5-8`.
- Impact: A learner copying snippets from older tutorials may hit API differences.
- Migration plan: Pin `minitest "~> 5.20"` in `Gemfile` if the goal is to teach mainstream Minitest. Alternatively, embrace 6.x and document why.

### No `.ruby-version` file

- Risk: `.gitignore:6` ignores `.ruby-version`, so different machines run different Rubies. CI runs 3.2/3.3/3.4; the user's local machine may be older or newer.
- Files: `.gitignore:6`.
- Impact: "Works on my machine" bugs around pattern matching, keyword args, numbered block parameters.
- Migration plan: Commit a `.ruby-version` (or `.tool-versions`) declaring the lowest supported Ruby (e.g. `3.2.0`). Remove the line from `.gitignore`.

### `watchr` is unmaintained

- Risk: The `koans.watchr` script implies installing the `watchr` gem, which has been unmaintained for over a decade and does not advertise compatibility with current Ruby.
- Files: `koans.watchr:1-11`, `src/koans.watchr:1-11`.
- Impact: Following old README content, learners install an abandoned gem.
- Migration plan: Delete both `.watchr` files now that `bin/koans watch` exists.

## Missing Critical Features

### No `bin/koans init` / install flow

- Problem: The CLI assumes the user already has `koans/` populated. There is no first-run experience that explains what to do, no `bin/koans init` that creates `.path_progress` empty, configures the editor, etc. Rustlings, by contrast, has `rustlings init`.
- Blocks: A clean Rustlings-style on-ramp.
- Fix approach: Add `bin/koans init` to scaffold `koans/`, run `rake gen`, write a fresh `.path_progress`, print the next-step instructions. Listed explicitly in the overhaul memo.

### No exercise / solution split

- Problem: The current model uses inline `#--`/`#++` markers in `src/*.rb` to hide answers from the generated `koans/` (`Rakefile:34-54`, `bin/koans:329-345`). There is no separate `solutions/` directory, no per-exercise solution file, no way to ask "show me the canonical solution for `about_iteration.rb`".
- Blocks: Self-paced learners who get stuck cannot consult a reference solution without diffing `src/` against `koans/` manually.
- Fix approach: Adopt the Rustlings layout: `exercises/`, `solutions/`, optional `info.toml` per exercise. The overhaul memo treats this as a core requirement.

### No exercise metadata / hints database

- Problem: Hints today are scraped from the comment block above the failing `def test_*` (`bin/koans:301-318`). That works for koans whose authors wrote good comments, but is silent for the rest.
- Blocks: Quality of the `bin/koans hint` command depends on the koan author's discipline.
- Fix approach: Per-exercise `info.toml` (or YAML) with structured `name`, `path`, `mode`, `hint`, `prerequisites`, `next`.

### No linter / RuboCop / Standard integration

- Problem: There is no `.rubocop.yml`, no `standard.yml`, no `.rubocop_todo.yml`. The overhaul memo specifically calls out RuboCop / `ruby -w` warnings as part of the "real Ruby toolchain" learners should encounter.
- Files: None — `.rubocop*` does not exist.
- Blocks: Pedagogical realism (Frente 2 in the memo).
- Fix approach: Add RuboCop or Standard with a beginner-friendly config. Wire into CI alongside `bundle exec rake test check`.

### No type checking exposure (RBS / Steep / Sorbet)

- Problem: Modern Ruby has RBS in the standard library. The koans never mention it.
- Blocks: Frente 1 (modernization) of the overhaul.
- Fix approach: Add an optional advanced chapter on RBS / `rbs` CLI / `steep`.

## Test Coverage Gaps

### `tests/` only covers the CLI surface and a sliver of `Neo::Sensei`

- What's tested:
  - `tests/koans_cli_test.rb` — `help`, `list`, `next`, `hint`, `reset` exit behaviors via `Open3` (5 tests).
  - `tests/check_test.rb` — `rake check:asserts` and `rake check:abouts` produce `OK` (2 tests).
  - `tests/neo_output_test.rb` — three `Neo::Sensei#guide_through_error` and `assert_nothing_raised` paths (3 tests).
- What's NOT tested:
  - The actual `walk` flow (`bin/koans:43-47`, `Rakefile:60-67`). No test confirms that a clean `rake regen && rake walk` produces a known first failure.
  - `Neo::Koan#meditate` lifecycle — `setup`/`teardown` ordering, exception handling on teardown (`src/neo.rb:463-477`).
  - `Neo::ThePath#walk` — the `catch(:neo_exit)` behavior and the `step_count` arithmetic (`src/neo.rb:534-554`).
  - `Neo::Sensei#observe` — progress tracking, "expanded your awareness" vs "damaged your karma" branches (`src/neo.rb:240-254`).
  - `Neo::Koan.command_line` — the `-n/pattern/` flag parsing (`src/neo.rb:493-508`).
  - `Koans.remove_solution` regex behavior (`Rakefile:24-32`) and `Koans.make_koan_file` state machine (`Rakefile:34-54`).
  - The CLI's `make_koan_file` / `remove_solution` duplicates (`bin/koans:329-354`).
  - The `watch` loop (`bin/koans:49-70`).
  - Generation idempotence: regenerating `koans/` should be a no-op.
- Files: `tests/koans_cli_test.rb`, `tests/check_test.rb`, `tests/neo_output_test.rb`.
- Risk: Refactoring the runner or the CLI would silently break learner-facing behavior. The solution-stripping regex in particular has zero direct tests.
- Priority: High — these are the highest-leverage things to test before the planned overhaul touches them.

### No CI matrix for JRuby or TruffleRuby

- Files: `.github/workflows/ci.yml:8-11` lists `["3.2", "3.3", "3.4"]` only.
- Risk: `about_java_interop.rb` is shipped but never tested. Any JRuby regression goes unnoticed.
- Priority: Low if the overhaul drops JRuby; High otherwise.

### No regression test for "hint must not leak the answer"

- Files: `bin/koans:104-124`, `bin/koans:301-318`.
- Risk: The hint-extraction logic walks comments above `def test_*`. If a future koan has the answer in the comment block, `bin/koans hint` will print it. There is no automated guard.
- Priority: Medium. Add a test that for every koan step, `hint` output does not contain the source line of the assertion's expected value.

---

*Concerns audit: 2026-05-07*
