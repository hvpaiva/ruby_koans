<!-- GSD:project-start source:PROJECT.md -->
## Project

**Ruby Path *(working title — final name TBD)***

A modern, Rustlings-inspired learning tool for Ruby 4+ that replaces the legacy Edgecase Ruby Koans curriculum. The audience is people who already program in another language and want to learn idiomatic Ruby today. Learners install a gem, run `<cli> init`, and progress through exercises in their editor while a watcher gives live feedback — they read real Ruby errors, modify real code, use Minitest, and get exposed to the modern toolchain (Bundler, debug.gem, RuboCop, error_highlight) instead of filling `__` placeholders inside test methods.

**Core Value:** **A self-paced learner can install the tool, work through every exercise, and finish feeling they understand modern Ruby (3.x/4.x) the way the community actually writes it today.** If everything else fails, this single experience must work.

### Constraints

- **Tech stack**: Ruby 4.0+, Bundler-managed gem, Minitest as the primary test framework, no Rails — Reason: the product is itself a small Ruby gem; ecosystem alignment with what learners will be exposed to.
- **Distribution**: Published as a RubyGem with a `<cli> init` bootstrap — Reason: matches Rustlings UX expectation and is the lowest-friction install path for learners on any platform with Ruby installed.
- **Audience-driven curriculum tone**: assume the learner already programs (any language) but does not know Ruby — Reason: cuts content describing universal concepts (variables, conditionals as a foundation) and frees space for Ruby-specific idioms.
- **No LLM/AI runtime dependency** — Reason: portability, offline use, no API keys, lower long-term maintenance burden.
- **Single-language curriculum (English) for v1** — Reason: maintenance cost; PT-BR comms with the maintainer happen separately from the product.
- **Solutions are local-first and "earned"** — Reason: spoiler control; matches Rustlings; preserves the contemplative spirit of the original Koans without the "fill the blank in the test" mechanic.
- **Maintainer scarcity** — only one developer (you) plus LLM assistance — Reason: roadmap should bias toward fewer, larger automated tasks rather than many small ones requiring human review; planning must include extensive research phases up front to compensate for limited Ruby seniority.
<!-- GSD:project-end -->

<!-- GSD:stack-start source:codebase/STACK.md -->
## Technology Stack

## Languages
- Ruby (MRI/CRuby) — entire codebase. Source koans in `src/*.rb`, generated exercises in `koans/*.rb`, the Sensei runtime in `src/neo.rb`, the CLI in `bin/koans`, internal tests in `tests/`, and Rake tasks in `Rakefile` + `rakelib/*.rake`.
- JRuby (optional) — `src/about_java_interop.rb` is conditionally loaded only when running under JRuby. `src/path_to_enlightenment.rb:38-40` and `src/neo.rb:18-22` gate this with `in_ruby_version("jruby")`.
- ERB-free plain-text fixtures — `src/example_file.txt`, `src/GREED_RULES.txt` (no template engine; just `.txt` assets).
## Runtime
- Ruby 3.2, 3.3, 3.4 — explicitly tested via the CI matrix in `.github/workflows/ci.yml:11`.
- Earlier versions of Ruby still survive in version-gating helpers (`src/neo.rb:18-35` defines `ruby_version?`, `in_ruby_version`, `before_ruby_version`), and `path_to_enlightenment.rb` still branches on `"2"`, `"3"`, `"4"`, `"2.7"`, `"jruby"`. CI does not exercise JRuby or Ruby 2.x.
- The CLI uses `RbConfig.ruby` (`bin/koans:172`) so it always re-invokes the active interpreter rather than hardcoding `ruby`.
- Bundler — declared via `Gemfile` and locked by `Gemfile.lock`.
- `BUNDLED WITH 4.0.8` (`Gemfile.lock:25-26`).
- Lockfile: present (`Gemfile.lock`).
- `.gitignore:7` ignores `Gemfile.lock` (so the committed lockfile is intentional but no longer protected from local mutation by gitignore — see CONCERNS).
## Frameworks
- Rake 13.4.2 — task runner driving koan generation (`rake gen`, `rake regen`), the default walk (`rake walk_the_path`), packaging (`rake package`/`rake zip`), and deployment (`rake upload`). Defined in `Rakefile`, `rakelib/checks.rake`, `rakelib/run.rake`, `rakelib/test.rake`.
- Custom Neo test framework (`src/neo.rb`) — homegrown assertion + runner (`Neo::Koan`, `Neo::Sensei`, `Neo::Assertions`, `Neo::ThePath`, `Neo::Color`). Provides `assert`, `assert_equal`, `assert_match`, `assert_raise`, `assert_nothing_raised`, plus the meditation/karma narration. Auto-runs via an `END {}` block (`src/neo.rb:557-562`) unless `ENV['NEO_DISABLE_END'] == 'true'`.
- Minitest 6.0.2 — used only for this fork's internal project tests under `tests/` (e.g. `tests/koans_cli_test.rb`, `tests/check_test.rb`, `tests/neo_output_test.rb`). Wired up via `Rake::TestTask` in `rakelib/test.rake`. `tests/test_helper.rb` requires `minitest/autorun`, `rake`, and `stringio`.
- Note: the koans themselves do **not** use Minitest. They run on the bespoke `Neo::Koan` framework in `src/neo.rb`.
- Rake's `FileList`/`pathmap` drive incremental koan generation (`Rakefile:10-11`, `Rakefile:112-116`).
- `zip` (system binary) — invoked by `rake package` to produce `download/rubykoans.zip` (`Rakefile:88`).
- `scp` (system binary) — invoked by `rake upload` to ship the zip to a remote host (`Rakefile:96`).
- `clear` (system binary) — invoked by the watcher and `bin/koans watch` to clear the terminal (`koans.watchr:2`, `bin/koans:182`).
- A custom CLI in `bin/koans` provides `walk`, `watch`, `list`, `next`, `hint`, `reset`, `help` (see `bin/koans:16-374`). It reuses the koan generation logic from `Rakefile` but reimplements `make_koan_file`/`remove_solution` locally (`bin/koans:329-354`).
## Key Dependencies
- `rake` 13.4.2 — driver for the canonical workflow (`rake`, `rake walk`, `rake gen`, `rake regen`, `rake watch`, `rake test`, `rake check`).
- `minitest` 6.0.2 — internal test framework for this fork only.
- `drb` 2.2.3 — pulled in by minitest 6.x.
- `prism` 1.9.0 — pulled in by minitest 6.x.
- `rake/testtask` — used in `rakelib/test.rake` to define the `test` task scanning `tests/**/*_test.rb`.
- `rake/clean` — used in `Rakefile:4` to register `**/*.rbc` for clean.
- `fileutils`, `rbconfig`, `English`, `open3`, `tmpdir`, `stringio` — Ruby stdlib modules used by the CLI and tests (`bin/koans:4-6`, `tests/koans_cli_test.rb:3-5`, `tests/test_helper.rb:1-3`).
- `win32console` (optional, soft `require`) — `src/neo.rb:6-9` rescues `LoadError`. Not declared in `Gemfile`; only used when running on Windows under MRI to enable ANSI colors.
## Configuration
- The project has **no `.env` files** and **no application-level secrets**. It runs entirely offline.
- Recognized environment variables:
- `Gemfile`, `Gemfile.lock` — Bundler manifests.
- `Rakefile`, `rakelib/checks.rake`, `rakelib/run.rake`, `rakelib/test.rake` — Rake task definitions.
- `koans.watchr` — top-level watchr DSL script (`watch(...)` block); runs `ruby bin/koans walk` on koan file changes.
- `koans/Rakefile`, `koans/path_to_enlightenment.rb`, `koans/koans.watchr` — copies that ship alongside the generated exercise set so a learner can `cd koans && rake` standalone.
- No JS/TS, no webpack, no compile step. The "build" is the koan generator (`rake gen`), which strips solutions from `src/*.rb` into `koans/*.rb`.
## Platform Requirements
- Ruby 3.2, 3.3, or 3.4 with Bundler.
- Standard POSIX tooling for the full workflow: `clear`, `zip`, `scp`, `rm`, `cp`. Linux and macOS work without extra setup. Windows requires `win32console` for colored output; otherwise `Neo::Color.use_colors?` falls back to plain text (`src/neo.rb:125-144`).
- Optional: JRuby — only needed if the learner wants `about_java_interop.rb` to load.
- This is a learning project; there is no production runtime. The only "deployment" target is the static download artifact `download/rubykoans.zip`, historically pushed to `linode:sites/onestepback.org/download` via `rake upload` (`Rakefile:95-97`, `DEPLOYING:1-12`).
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

## Naming Patterns
- Curriculum files use `snake_case` and a topical `about_` prefix:
- Project-style koans append `_project` (or `_project_2`):
- Test files end in `_test.rb`: `tests/check_test.rb`,
- Rake task files use `.rake` and live in `rakelib/`:
- The single CLI entrypoint has no extension: `bin/koans`.
- Each koan file defines exactly one `About<Topic>` class extending
- Helper classes inside a koan use `CamelCase` and are nested inside the
- Tooling uses module-namespaced classes: `Neo::Sensei`, `Neo::Koan`,
- Always start with `test_` followed by an English-style snake_case
- The `Neo::Koan.test_pattern` regex (`src/neo.rb:525`) is `/^test_/`. Any
- `snake_case` for locals and instance variables.
- The pair `expected_value` / `actual_value` is used when the lesson is the
- Top-level constants are `SCREAMING_SNAKE_CASE` (`PROGRESS_FILE_NAME`,
## The Koan Placeholder Vocabulary
| Placeholder | Meaning | Defined at |
|-------------|---------|------------|
| `__` | Generic value blank ("FILL ME IN" string in the koan) | `src/neo.rb:39` |
| `_n_` | Numeric blank (defaults to `999999`) | `src/neo.rb:48` |
| `___` | Error-class blank (defaults to `FillMeInError`) | `src/neo.rb:57` |
| `____` | Method-name blank — sends `method` to `self` | `src/neo.rb:67` |
| `# __` (trailing comment) | Marker that this line is part of the puzzle | stripped by `Rakefile:30` |
- `__(answer)` for a value blank.
- `_n_(answer)` for a numeric blank.
- `___(ErrorClass)` for an exception blank.
- `obj.____(:method)` for a method-name blank.
- Wrap full solution bodies in `#--` / `#++` so `rake gen` regenerates a
## Code Style
- No formatter is configured. No `.rubocop.yml`, no `.editorconfig`, no
- 2-space indentation everywhere.
- Single-line method bodies use `def ... end` rather than endless methods.
- Tooling code (`bin/koans`, `tests/*_test.rb`) opts in to
- No linter is configured.
- The repo enforces curriculum integrity through `rake check`
## Imports & Requires
- `bin/koans:4-6`: `require "fileutils"`, `"rbconfig"`, `"English"`.
- Tests use `require_relative "test_helper"` (`tests/check_test.rb:1`,
## Error Handling
## Logging & User Output
- Progress and lesson output → `$stdout` via `puts`/`print`.
- Errors and usage messages → `$stderr` via `warn` (`bin/koans:36-39`,
## Comments
## Function & Method Design
- One concept per `test_` method. Keep the method body small enough to
- Helper classes/modules used by the lesson go inside the same `About*`
- When an example must reopen a class to demonstrate a concept, do it
- Methods are short and dispatched from a `case` in `RubyKoansCLI.call`
- Methods return integer exit codes so the dispatcher can `exit` on them
- Class-level `class << self` block on `RubyKoansCLI` keeps everything as
## Module Design
## Where Conventions Differ Between `src/` and `koans/`
| In `src/about_*.rb` | In `koans/about_*.rb` |
|---------------------|-----------------------|
| `__(2)` | `__` |
| `_n_(7)` | `_n_` |
| `___(NoMethodError)` | `___` |
| `obj.____(:downcase)` | `obj.____` |
| `# __` at end of line | (line keeps everything except `# __`) |
| Lines between `#--` and `#++` | (removed entirely) |
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

## System Overview
```text
```
## Component Responsibilities
| Component | Responsibility | File |
|-----------|----------------|------|
| Top-level Rakefile | Orchestrate generation, default `walk_the_path`, packaging, watch alias | `Rakefile` |
| `Koans` module | Solution-stripping logic (`remove_solution`, `make_koan_file`) used by `:gen` | `Rakefile` (lines 17-55) |
| Modern CLI | `walk`/`watch`/`list`/`next`/`hint`/`reset`/`help` dispatcher | `bin/koans` |
| Watchr config (root) | Tells `watchr` to re-run `bin/koans walk` on changes inside `koans/` | `koans.watchr` |
| Watchr config (student) | Same loop, but launched from inside `koans/` (uses `../bin/koans`) | `koans/koans.watchr`, `src/koans.watchr` |
| Canonical sources | Master koans with embedded answers and `#--`/`#++` solution blocks | `src/about_*.rb`, `src/triangle.rb` |
| Source manifest | Defines koan order via `require` lines, gated by `in_ruby_version` | `src/path_to_enlightenment.rb` |
| Neo runner | `Neo::Koan` (test base), `Neo::Sensei` (reporter), `Neo::ThePath` (driver), `Neo::Assertions` (matchers) | `src/neo.rb` |
| Generated working copy | Student-editable koans (answers stripped) plus a verbatim `neo.rb`/`path_to_enlightenment.rb` | `koans/about_*.rb`, `koans/neo.rb`, `koans/path_to_enlightenment.rb` |
| Student Rakefile | `task :test` that runs `path_to_enlightenment.rb` from inside `koans/` | `koans/Rakefile` |
| Triangle exercise | Free-form module the learner has to implement | `src/triangle.rb` -> `koans/triangle.rb` |
| Progress ledger | Comma-separated list of pass counts written by `Neo::Sensei#add_progress`, read by CLI `next`/`hint` | `koans/.path_progress` |
| Helper rake tasks | `rake check:abouts`, `rake check:asserts`, internal `rake test` | `rakelib/checks.rake`, `rakelib/test.rake`, `rakelib/run.rake` |
| Project-test helper | Loads Rakefile + minitest for `check_test.rb` | `tests/test_helper.rb` |
| CLI integration tests | Spawn `bin/koans` via `Open3` and assert on stdout | `tests/koans_cli_test.rb` |
| Neo output tests | Verify `Sensei#guide_through_error` never leaks the answer | `tests/neo_output_test.rb` |
| Assertion sanity tests | Run `rake check:abouts`/`check:asserts` and capture stdout | `tests/check_test.rb` |
| Distribution zip | Packaged koans for download | `download/rubykoans.zip` (built by `rake zip`) |
## Pattern Overview
- The codebase has a **dual-tree layout**: `src/` (canonical, with answers) is the build input; `koans/` (generated, answer-stripped) is what learners edit. The build is line-oriented stripping, not templating.
- The test runner is **hand-rolled, not minitest/RSpec**: `Neo::Koan` registers subclasses via `inherited`, captures test method names via `method_added`, and walks them inside an `END` block defined in `koans/neo.rb` (same `neo.rb` as `src/neo.rb`, copied verbatim by the generator).
- Execution is **fail-fast**: `Neo::Sensei#observe` calls `throw :neo_exit` on the first failure, so the path stops at the first koan that needs meditation.
- The **modern `bin/koans` CLI** does not replace the Rake flow — it wraps it. `walk`/`watch` shell out to `rake gen`, then run `koans/path_to_enlightenment.rb` directly. `list`/`next`/`hint` introspect koan order without running tests by loading `src/path_to_enlightenment.rb` with `NEO_DISABLE_END=true`.
- **Progress is a file, not a database**: `koans/.path_progress` accumulates pass counts (e.g. `0,0,0,0,0,0,0,0`). `Neo::Sensei` and `bin/koans` both read/write it, and the CLI honours `KOANS_PROGRESS_FILE` so tests can isolate state.
- Two `koans.watchr` files exist (`koans.watchr` at the repo root, `koans/koans.watchr`); both shell out to `bin/koans walk` so the watcher contract is uniform regardless of where it is launched.
## Layers
- Purpose: Translate a learner's intent ("walk the path", "watch", "reset hashes") into a concrete generation + run sequence.
- Location: `Rakefile`, `bin/koans`, `koans.watchr`, `koans/koans.watchr`.
- Contains: Rake tasks, `RubyKoansCLI` module, watchr blocks.
- Depends on: Generation Layer (it invokes `:gen`/`:regen` or replicates `make_koan_file`), Runner Layer (it `system`s `path_to_enlightenment.rb`).
- Used by: Humans and the watcher loop.
- Purpose: Convert `src/*` into `koans/*` by stripping answers between `#--` / `#++` markers and replacing solution placeholders (`__(value)` -> `__`, `_n_(value)` -> `_n_`, etc.).
- Location: `Rakefile` lines 17-55 (`Koans.remove_solution`, `Koans.make_koan_file`), `Rakefile` lines 99-116 (`:gen`, `:regen`, file rules), `bin/koans` lines 329-354 (a small re-implementation used by `bin/koans reset <file>`).
- Contains: `Koans` module (Rake DSL), `RubyKoansCLI.make_koan_file` / `RubyKoansCLI.remove_solution` (CLI duplicate).
- Depends on: `src/*` (read), `koans/*` (write).
- Used by: `rake gen`, `rake regen`, `rake walk_the_path`, `bin/koans walk`, `bin/koans watch`, `bin/koans reset`.
- Purpose: Drive each koan's test methods, format failures, persist progress, render the end-of-path artwork.
- Location: `src/neo.rb` (canonical), copied verbatim into `koans/neo.rb` by the generator (the `Koans.make_koan_file` branch on line 35 of `Rakefile` does a `cp` when the filename matches `/neo/`).
- Contains: `Neo::Koan`, `Neo::Sensei`, `Neo::ThePath`, `Neo::Assertions`, `Neo::Color`, top-level helpers (`__`, `_n_`, `___`, `____`, `in_ruby_version`, `before_ruby_version`).
- Depends on: standard library only (`Gem::Version`, optional `win32console`).
- Used by: `koans/path_to_enlightenment.rb` (which `require`s every `about_*` file; each file `require`s `neo`, registering itself as a `Neo::Koan` subclass; the `END` block at the bottom of `neo.rb` then walks all subclasses in registration order).
- Purpose: Verify this fork's additions (CLI, no-spoiler error formatting, consistency checks) without running the koans themselves.
- Location: `tests/`.
- Contains: minitest test cases.
- Depends on: minitest, `Rake.application.load_rakefile`, `Open3` for CLI subprocess tests.
- Used by: `rake test` (defined in `rakelib/test.rake`).
## Data Flow
### Primary Request Path: `rake` (or `rake walk_the_path`)
### Secondary Flow: `bin/koans walk`
### Secondary Flow: `bin/koans watch` (and `rake watch` / `koans.watchr`)
### Secondary Flow: `bin/koans list` / `next` / `hint`
### Secondary Flow: `bin/koans reset <file|all>`
### Secondary Flow: Internal `rake test`
- Source-of-truth state lives on disk: `src/*` (immutable input), `koans/*` (mutable working copy, the learner's edits live here), `koans/.path_progress` (append-only-ish ledger of pass counts).
- In-process state is module-level on `Neo::Koan` (`@subclasses`, `@test_methods`, `@tests_disabled`, `@test_pattern`) and on `Neo::Sensei` instances (per-walk).
- `bin/koans` memoises `@koan_steps` for the lifetime of a single CLI invocation (`bin/koans:207`).
## Key Abstractions
- Purpose: Declarative test container; subclasses register themselves and their `test_*` methods automatically.
- Examples: `src/about_asserts.rb` (`class AboutAsserts < Neo::Koan`), every `src/about_*.rb`.
- Pattern: Self-registering test class via `inherited` hook + `method_added` filter (`src/neo.rb:480-531`). No external test framework required.
- Purpose: Watches each step, prints colorised observations, persists pass count, renders the end screen, masks the failing assertion's expected/actual values.
- Examples: `src/neo.rb:205-433`.
- Pattern: Stateful observer that `throw :neo_exit` on first failure to short-circuit the walk.
- Purpose: Iterate `Neo::Koan.subclasses` in registration order and ask each koan to `meditate`.
- Examples: `src/neo.rb:534-554`.
- Pattern: Catch/throw-based early termination.
- Purpose: Replacement for minitest's matchers (`assert`, `assert_equal`, `assert_match`, `assert_raise`, `assert_nothing_raised`, etc.) so the koans never depend on a third-party assertion library.
- Examples: `src/neo.rb:147-203`.
- Pattern: Failure raises a custom `FailedAssertionError`, which `Sensei#guide_through_error` recognises so it can hide the answer.
- Purpose: Visible blanks the learner replaces; in `src/`, the same identifiers are *function calls* with the answer as the argument (`__(2)`, `___(NoMethodError)`), so the source koans pass when run from `src/`.
- Examples: top-level definitions in `src/neo.rb:39-76`; usage in every `src/about_*.rb`.
- Pattern: The build pipeline strips the parenthesised argument (regex in `Koans.remove_solution`, `Rakefile:24-32`), turning `__(2)` into `__`, which the runtime defines as `"FILL ME IN"`.
- Purpose: Mark blocks of canonical source that exist only to make the koans pass in `src/` and that must be omitted from the generated working copy.
- Examples: `src/about_asserts.rb:10-17`, `src/triangle.rb:18-23`, `src/about_dice_project.rb:9-17`.
- Pattern: State machine in `Koans.make_koan_file` (`Rakefile:38-53`) toggles `:copy`/`:skip`.
- Purpose: Single-file Ruby module that exposes the modern verbs (`walk`, `watch`, `list`, `next`, `hint`, `reset`, `help`).
- Examples: `bin/koans:8-376`.
- Pattern: Module-level singleton (`class << self`) with a `call(argv)` entry point.
## Entry Points
- Location: `Rakefile:57-70`.
- Triggers: User runs `rake` from the project root.
- Responsibilities: Generate koans, then walk the path until first failure.
- Location: `Rakefile:99-116`.
- Triggers: Explicit invocation, or as a dependency of `walk_the_path`.
- Responsibilities: Build/rebuild the `koans/` working copy from `src/`.
- Location: `Rakefile:72-75`.
- Triggers: User runs `rake watch`.
- Responsibilities: Delegates to `bin/koans watch`.
- Location: `rakelib/test.rake:3-7`, `rakelib/checks.rake:47-48`.
- Triggers: `rake test` (this fork's project tests), `rake check` (consistency checks).
- Responsibilities: Run minitest suite under `tests/`; verify `path_to_enlightenment.rb` requires every about file and that asserts have `__`/`_n_` placeholders.
- Location: `Rakefile:80-97`.
- Triggers: Distribution maintenance.
- Responsibilities: Build `download/rubykoans.zip` from `koans/*`; optionally `scp` it.
- Location: `bin/koans:1-378` (entry: `RubyKoansCLI.call(ARGV)` on line 378).
- Triggers: User runs `bin/koans walk|watch|list|next|hint|reset|help`.
- Responsibilities: Modern CLI dispatcher; every command exits with an explicit status code.
- Location: `koans.watchr:1-11`, `koans/koans.watchr:1-11`.
- Triggers: User runs `watchr koans.watchr`.
- Responsibilities: Re-run `bin/koans walk` (or `../bin/koans walk` from inside `koans/`) on `*.rb` / `*.txt` changes.
- Location: `koans/path_to_enlightenment.rb:1-44`.
- Triggers: Loaded by `ruby path_to_enlightenment.rb` from inside `koans/`; this is the actual program the runner spawns.
- Responsibilities: Add `koans/` to `$LOAD_PATH` and `require` every koan in canonical order; trigger the Neo `END` block.
- Location: `koans/Rakefile:1-12`.
- Triggers: User runs `rake` from inside `koans/` (a stripped-down task for learners working in the generated tree).
- Responsibilities: `task :test` runs `path_to_enlightenment.rb`.
## Architectural Constraints
- **Process model:** Single-process Ruby. The walker runs inside `ruby path_to_enlightenment.rb`, and `bin/koans walk`/`watch` spawn fresh subprocesses each iteration via `system`/`Open3`.
- **Run-once `END` hook:** `src/neo.rb:557-562` registers an `END {}` block that auto-runs the walk. Anyone loading `src/neo.rb` from another tool (CLI introspection, internal tests) **must** set `ENV['NEO_DISABLE_END'] = 'true'` before requiring it. This is done in `bin/koans:222` and `tests/neo_output_test.rb:3`.
- **Ordering is request-time, not declaration-time:** `Neo::Koan.subclasses` is in registration order, which equals the `require` order in `path_to_enlightenment.rb`. Reorder the requires, and you reorder the path.
- **Module-level mutable state:** `Neo::Koan.@subclasses`, `@test_methods`, `@tests_disabled`, `@test_pattern` are class-level. Loading the koans twice in one process appends — `bin/koans` introspection commands rely on a *single* load.
- **Generation contract:** `Koans.make_koan_file` only matches `/neo/` for verbatim copy, and the placeholder regexes are anchored on `\b`. New placeholder forms (e.g. `_____`) require updating both `Rakefile:24-32` and the duplicate in `bin/koans:347-354`.
- **No threading, no concurrency:** Tests stop on first failure; nothing is parallelised.
- **No circular imports:** `src/path_to_enlightenment.rb` -> each `about_*.rb` -> `neo.rb`. Linear.
- **Top-level helpers pollute Object:** `__`, `_n_`, `___`, `____`, `in_ruby_version`, `before_ruby_version` are defined at the top level of `neo.rb` (`src/neo.rb:18-76`); `____` is added to `Object`. Anything `require`-ing `neo.rb` inherits this.
- **Two copies of the generation logic:** `Koans` module (Rakefile) and `RubyKoansCLI.make_koan_file`/`remove_solution` (`bin/koans`). They must be kept in sync — see CONCERNS.md.
- **Two copies of `koans.watchr`:** root and `koans/`; both shell to `bin/koans walk`. They differ only in the relative path to `bin/koans` (`bin` vs `../bin`).
## Anti-Patterns
### Editing files in `src/` instead of `koans/`
### Loading `src/neo.rb` without `NEO_DISABLE_END`
### Using `puts` directly in failure formatting
### Adding a koan file but forgetting `require` in `path_to_enlightenment.rb`
### Skipping the placeholder convention
### Hand-writing files into `koans/` and committing them
## Error Handling
- `Neo::Assertions::FailedAssertionError` is a custom subclass; `assert*` helpers `flunk` to it (`src/neo.rb:148-152`).
- `Neo::Koan#meditate` rescues `StandardError` *or* `Neo::Sensei::FailedAssertionError`, attaching the exception via `failed(ex)` (`src/neo.rb:463-477`).
- `Neo::Sensei#guide_through_error` branches on `assert_failed?`: assertion failures print only the file:line; everything else prints the exception class + message (`src/neo.rb:362-375`).
- `Neo::Sensei#observe` calls `throw :neo_exit`, caught by `Neo::ThePath#each_step`'s `catch(:neo_exit)` (`src/neo.rb:543-553`). This is the entire fail-fast mechanism.
- `bin/koans` commands always return an integer status; `RubyKoansCLI.call` `exit`s with it (`bin/koans:16-41`). `run` swallows `Dir.chdir`/`system` failures into a `1` (`bin/koans:163-169`).
- `bin/koans reset` rescues `ArgumentError` from `normalize_target_file` (path-traversal guard) (`bin/koans:150-153`).
## Cross-Cutting Concerns
- `NEO_DISABLE_END` (skip the auto-walk `END` block)
- `SIMPLE_KOAN_OUTPUT` (boring vs artistic end screen, `src/neo.rb:93-95`)
- `NO_COLOR`, `ANSI_COLOR` (color toggling)
- `KOANS_WATCH_INTERVAL` (watcher poll interval, default `0.5`s)
- `KOANS_NO_CLEAR` (suppress screen clear in watch mode)
- `KOANS_PROGRESS_FILE` (override `.path_progress` location, used by tests)
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.github/skills/`, or `.codex/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
