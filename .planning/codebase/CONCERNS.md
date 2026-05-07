# Codebase Concerns

**Analysis Date:** 2026-05-07

## Tech Debt

**Duplicate koan generation logic:**
- Issue: Solution-stripping logic exists in both `Rakefile` and `bin/koans`, including near-identical `remove_solution` and `make_koan_file` implementations.
- Files: `Rakefile`, `bin/koans`
- Impact: Any future change to placeholder syntax, hidden solution markers, or generated file behavior must be made in two places or the classic rake flow and CLI flow diverge.
- Fix approach: Extract generation behavior into one shared Ruby file, for example `lib/ruby_koans/generator.rb`, and have `Rakefile` and `bin/koans` call the same methods.

**Generated `koans/` tree checked in locally but ignored by git:**
- Issue: `koans/*` is ignored while generated files exist under `koans/`; source files live under `src/` and are transformed into `koans/` by `rake gen` or `bin/koans walk`.
- Files: `.gitignore`, `src/`, `koans/`, `Rakefile`, `bin/koans`
- Impact: Edits made directly in `koans/` are local-only learner answers and can be deleted by `rake regen` or `bin/koans reset all`; contributors can accidentally inspect or modify generated content instead of canonical source.
- Fix approach: Treat `src/` as canonical for repository changes. Add documentation near `README.rdoc` and `bin/koans help` that implementation changes belong in `src/`, not `koans/`.

**Large support runtime concentrated in one file:**
- Issue: Assertions, progress tracking, color output, koan discovery, runner control flow, formatting, and global compatibility helpers are all implemented in `src/neo.rb`.
- Files: `src/neo.rb`, `koans/neo.rb`
- Impact: Changes to one concern can affect unrelated behavior through shared module/class state, global methods, and the `END` hook.
- Fix approach: Split `src/neo.rb` into explicit support modules while preserving the public API loaded by `src/path_to_enlightenment.rb`.

**Global monkey patches and process-wide settings:**
- Issue: The runtime sets `$VERBOSE = nil`, defines global helper methods (`__`, `_n_`, `___`, `ruby_version?`), reopens `Object`, and reopens `String`.
- Files: `src/neo.rb`, `koans/neo.rb`
- Impact: The support code changes process-global behavior for every loaded koan and for any tooling that loads `src/neo.rb` in-process.
- Fix approach: Keep global helpers stable for koan compatibility, but place new support behavior under `Neo::*` modules and avoid adding new `Object` or core-class methods.

## Known Bugs

**CLI progress-file override does not reach the classic runner:**
- Symptoms: `bin/koans list`, `bin/koans next`, and `bin/koans hint` read `KOANS_PROGRESS_FILE`, but `src/neo.rb` always writes and reads `.path_progress` relative to the runner working directory.
- Files: `bin/koans`, `src/neo.rb`, `koans/neo.rb`, `tests/koans_cli_test.rb`
- Trigger: Run `KOANS_PROGRESS_FILE=/tmp/custom-progress bin/koans walk`; the subprocess in `koans/` records progress through `Neo::Sensei::PROGRESS_FILE_NAME = '.path_progress'` instead of the supplied path.
- Workaround: Run the classic path from `koans/` and use the default `koans/.path_progress`, or use the progress override only for read-only CLI commands.

**Random dice koan can fail by chance:**
- Symptoms: Two consecutive `DiceSet#roll(5)` calls can produce identical arrays and fail `test_dice_values_should_change_between_rolls`.
- Files: `src/about_dice_project.rb`, `koans/about_dice_project.rb`
- Trigger: Run the completed source koans when `rand(6) + 1` produces the same five-value sequence twice.
- Workaround: Re-run the koans. For deterministic checks, test that `roll` creates values in range and updates state without requiring two random rolls to differ.

**Setup failures skip teardown:**
- Symptoms: If a koan overrides `setup` and raises, `teardown` is not invoked for that koan.
- Files: `src/neo.rb`, `koans/neo.rb`
- Trigger: Add a koan subclass whose `setup` raises before `Neo::Koan#meditate` enters its `begin` block.
- Workaround: Keep koan `setup` methods side-effect-light. Move `setup` inside the protected section if teardown guarantees become important.

## Security Considerations

**Dynamic file loading from command-line arguments:**
- Risk: `Neo::Koan.command_line` loads any existing file passed as an argument, which executes that Ruby file in the current process.
- Files: `src/neo.rb`, `koans/neo.rb`
- Current mitigation: The normal CLI path runs `ruby path_to_enlightenment.rb` from `bin/koans` and does not expose arbitrary file paths through documented commands.
- Recommendations: Do not pass untrusted file paths to `src/path_to_enlightenment.rb`. If file arguments become user-facing, restrict them to koan files under `src/` or `koans/`.

**Use of `eval`, `instance_eval`, and `module_eval`:**
- Risk: Dynamic evaluation can execute arbitrary Ruby if strings become user-controlled.
- Files: `src/neo.rb`, `src/about_methods.rb`, `src/about_classes.rb`, `koans/neo.rb`, `koans/about_methods.rb`, `koans/about_classes.rb`
- Current mitigation: The evaluated strings are static educational examples or generated from the internal `Neo::Color::COLORS` constant.
- Recommendations: Keep evaluated strings static. Prefer `define_method` over `module_eval` for new generated methods in `src/neo.rb`.

**Shell commands are present but use controlled inputs:**
- Risk: Shell execution exists in build tasks and terminal control.
- Files: `Rakefile`, `bin/koans`, `tests/koans_cli_test.rb`
- Current mitigation: `bin/koans` uses array-form `system(*command)` for Ruby and rake execution, `tests/koans_cli_test.rb` uses `Open3.capture3` with explicit arguments, and interpolated rake shell commands use repository constants.
- Recommendations: Continue using array-form process execution for new CLI commands. Avoid interpolating user-provided paths into `sh` strings in `Rakefile`.

## Performance Bottlenecks

**Watch mode uses polling:**
- Problem: `bin/koans watch` recalculates file signatures every `KOANS_WATCH_INTERVAL` seconds by statting all Ruby/text files under `koans/`.
- Files: `bin/koans`
- Cause: `watched_files_signature` scans `Dir[File.join(KOANS_DIR, "*.{rb,txt}")]` in a loop with a default 0.5 second sleep.
- Improvement path: Polling is acceptable for this small repo. Use a filesystem notification gem only if watch mode expands to many directories or hundreds of files.

**Repeated full koan loading for CLI metadata commands:**
- Problem: `bin/koans list`, `bin/koans next`, and `bin/koans hint` load the full koan path to discover classes and test methods.
- Files: `bin/koans`, `src/path_to_enlightenment.rb`, `src/neo.rb`
- Cause: `koan_steps` calls `load_koan_definitions`, which loads `src/path_to_enlightenment.rb` and all required koan files.
- Improvement path: Keep this approach for correctness while the path is small. Add cached metadata only if startup time becomes visible in normal CLI use.

## Fragile Areas

**Progress file format and concurrency:**
- Files: `src/neo.rb`, `koans/neo.rb`, `bin/koans`
- Why fragile: Progress is a comma-separated append-only file with no locking and tolerant integer parsing. Concurrent koan runs can interleave writes, and non-numeric trailing content becomes `0` in CLI progress reads.
- Safe modification: Centralize progress read/write behavior and use atomic writes or file locks if concurrent CLI usage is supported.
- Test coverage: `tests/koans_cli_test.rb` covers read-only progress lookup through a temporary progress file, but no test covers writes from `bin/koans walk` into an overridden progress file.

**Regex-based source parsing:**
- Files: `bin/koans`, `rakelib/checks.rake`, `src/path_to_enlightenment.rb`
- Why fragile: CLI metadata and consistency checks use regexes to parse `require` lines and `def test_*` lines. Formatting changes, multi-line definitions, comments, or metaprogrammed tests can be missed.
- Safe modification: Keep `src/path_to_enlightenment.rb` requires and koan test definitions simple: one `require` per line and direct `def test_*` methods.
- Test coverage: `tests/koans_cli_test.rb` verifies representative `list`, `next`, and `hint` output. `tests/check_test.rb` verifies checks emit `OK`, but it does not assert behavior for malformed or extra requirements.

**Exception handling catches broad exception classes:**
- Files: `src/neo.rb`, `koans/neo.rb`, `tests/neo_output_test.rb`
- Why fragile: Assertion helpers rescue `Exception`, which includes process-control exceptions such as `SystemExit` and `Interrupt`; koan execution itself rescues `StandardError` and custom assertion failures.
- Safe modification: Use `StandardError` for new runtime-level rescue paths unless the educational assertion explicitly needs to demonstrate broader behavior.
- Test coverage: `tests/neo_output_test.rb` covers assertion output for normal runtime errors and assertion failures, but not interrupt/system-exit behavior.

**Proxy project forwards with `send` and lacks `respond_to_missing?`:**
- Files: `src/about_proxy_object_project.rb`, `koans/about_proxy_object_project.rb`
- Why fragile: `Proxy#method_missing` forwards all messages with `@object.send`, records invalid messages before raising, and does not implement `respond_to_missing?`.
- Safe modification: For production-style proxy behavior, use `public_send`, add `respond_to_missing?`, and decide whether failed message attempts should be recorded.
- Test coverage: Existing koans check forwarding, invalid message raising, and call counting, but they do not check `respond_to?`, private method forwarding, or failed-call recording semantics.

## Scaling Limits

**Single-process educational runner:**
- Current capacity: The runner is designed for the small path defined by `src/path_to_enlightenment.rb` and the generated `koans/` tree.
- Limit: Global state in `Neo::Koan.subclasses`, `Neo::Koan.testmethods`, and `Neo::Sensei` makes isolated parallel execution difficult.
- Scaling path: Fork separate Ruby processes per path or refactor discovery state into explicit runner instances before adding parallel execution.

## Dependencies at Risk

**Ignored lockfile in a CI-tested Ruby project:**
- Risk: `Gemfile.lock` exists locally but is ignored by `.gitignore`, while CI installs dependencies with `bundler-cache: true`.
- Impact: CI and contributors resolve the latest compatible `minitest` and `rake` versions instead of a committed dependency set, which can introduce behavior changes without code changes.
- Migration plan: Either commit `Gemfile.lock` for reproducible CI, or document that this repository intentionally tests against floating latest dependencies.

## Missing Critical Features

**No critical product feature gap detected:**
- Problem: The project is an educational Ruby Koans runner and exercise set; core behavior is present through `bin/koans`, `Rakefile`, `src/`, and `tests/`.
- Blocks: Not applicable.

## Test Coverage Gaps

**CLI mutation commands:**
- What's not tested: `bin/koans walk`, `bin/koans watch`, `bin/koans reset <file>`, and `bin/koans reset all` behavior.
- Files: `bin/koans`, `tests/koans_cli_test.rb`
- Risk: Regressions in generation, reset safety, progress writing, or watch behavior can pass the current test suite.
- Priority: High

**Packaging and deployment tasks:**
- What's not tested: `rake zip`, `rake package`, `rake upload`, and `rake regen` behavior.
- Files: `Rakefile`
- Risk: Distribution artifacts and upload commands can break unnoticed because CI runs `bundle exec rake test check` only.
- Priority: Medium

**Educational project edge cases:**
- What's not tested: Deterministic dice behavior, proxy `respond_to?` behavior, private-method forwarding, and score validation for invalid dice values.
- Files: `src/about_dice_project.rb`, `src/about_proxy_object_project.rb`, `src/about_scoring_project.rb`
- Risk: Learner-facing examples can encode fragile assumptions or incomplete Ruby idioms.
- Priority: Medium

---

*Concerns audit: 2026-05-07*
