<!-- refreshed: 2026-05-07 -->
# Architecture

**Analysis Date:** 2026-05-07

## System Overview

```text
┌──────────────────────────────────────────────────────────────────────────────┐
│                              Learner Entry Points                             │
├───────────────────────┬───────────────────────┬──────────────────────────────┤
│  rake (default)       │  bin/koans <cmd>      │  bin/koans watch /           │
│  `Rakefile`           │  `bin/koans`          │  rake watch / koans.watchr   │
└──────────┬────────────┴──────────┬────────────┴──────────────┬───────────────┘
           │                       │                            │
           │ invokes                │ shells out to              │ polls files
           ▼                       ▼                            ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                       Generation Pipeline (Rake)                              │
│  `Rakefile` :gen / :regen      `rakelib/checks.rake`   `rakelib/test.rake`    │
│  reads `src/*` -> writes `koans/*` via `Koans.make_koan_file`                 │
└──────────────────────────┬───────────────────────────────────────────────────┘
                           │ generates / refreshes
                           ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                     Student-Facing Working Copy                               │
│  `koans/about_*.rb`  `koans/neo.rb`  `koans/path_to_enlightenment.rb`         │
│  `koans/triangle.rb` `koans/Rakefile` `koans/.path_progress`                  │
└──────────────────────────┬───────────────────────────────────────────────────┘
                           │ ruby path_to_enlightenment.rb
                           ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                        Neo Test Runner (in-process)                           │
│  `koans/neo.rb` -> module Neo: { Koan, Sensei, ThePath, Assertions, Color }   │
│  END {} block walks subclasses in registration order, observes failures,      │
│  records progress to `koans/.path_progress`                                   │
└──────────────────────────┬───────────────────────────────────────────────────┘
                           │ stdout / exit status
                           ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                         Internal Project Tests                                │
│  `tests/koans_cli_test.rb`  `tests/neo_output_test.rb`  `tests/check_test.rb` │
│  `tests/test_helper.rb` (loads Rake, minitest)                                │
└──────────────────────────────────────────────────────────────────────────────┘
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

**Overall:** Source-to-exercise generation pipeline with a small custom in-process test runner ("Neo") and a thin operational layer (Rake tasks + a Ruby CLI + a watchr loop).

**Key Characteristics:**
- The codebase has a **dual-tree layout**: `src/` (canonical, with answers) is the build input; `koans/` (generated, answer-stripped) is what learners edit. The build is line-oriented stripping, not templating.
- The test runner is **hand-rolled, not minitest/RSpec**: `Neo::Koan` registers subclasses via `inherited`, captures test method names via `method_added`, and walks them inside an `END` block defined in `koans/neo.rb` (same `neo.rb` as `src/neo.rb`, copied verbatim by the generator).
- Execution is **fail-fast**: `Neo::Sensei#observe` calls `throw :neo_exit` on the first failure, so the path stops at the first koan that needs meditation.
- The **modern `bin/koans` CLI** does not replace the Rake flow — it wraps it. `walk`/`watch` shell out to `rake gen`, then run `koans/path_to_enlightenment.rb` directly. `list`/`next`/`hint` introspect koan order without running tests by loading `src/path_to_enlightenment.rb` with `NEO_DISABLE_END=true`.
- **Progress is a file, not a database**: `koans/.path_progress` accumulates pass counts (e.g. `0,0,0,0,0,0,0,0`). `Neo::Sensei` and `bin/koans` both read/write it, and the CLI honours `KOANS_PROGRESS_FILE` so tests can isolate state.
- Two `koans.watchr` files exist (`koans.watchr` at the repo root, `koans/koans.watchr`); both shell out to `bin/koans walk` so the watcher contract is uniform regardless of where it is launched.

## Layers

**Entry / Orchestration Layer:**
- Purpose: Translate a learner's intent ("walk the path", "watch", "reset hashes") into a concrete generation + run sequence.
- Location: `Rakefile`, `bin/koans`, `koans.watchr`, `koans/koans.watchr`.
- Contains: Rake tasks, `RubyKoansCLI` module, watchr blocks.
- Depends on: Generation Layer (it invokes `:gen`/`:regen` or replicates `make_koan_file`), Runner Layer (it `system`s `path_to_enlightenment.rb`).
- Used by: Humans and the watcher loop.

**Generation Layer:**
- Purpose: Convert `src/*` into `koans/*` by stripping answers between `#--` / `#++` markers and replacing solution placeholders (`__(value)` -> `__`, `_n_(value)` -> `_n_`, etc.).
- Location: `Rakefile` lines 17-55 (`Koans.remove_solution`, `Koans.make_koan_file`), `Rakefile` lines 99-116 (`:gen`, `:regen`, file rules), `bin/koans` lines 329-354 (a small re-implementation used by `bin/koans reset <file>`).
- Contains: `Koans` module (Rake DSL), `RubyKoansCLI.make_koan_file` / `RubyKoansCLI.remove_solution` (CLI duplicate).
- Depends on: `src/*` (read), `koans/*` (write).
- Used by: `rake gen`, `rake regen`, `rake walk_the_path`, `bin/koans walk`, `bin/koans watch`, `bin/koans reset`.

**Runner Layer (Neo):**
- Purpose: Drive each koan's test methods, format failures, persist progress, render the end-of-path artwork.
- Location: `src/neo.rb` (canonical), copied verbatim into `koans/neo.rb` by the generator (the `Koans.make_koan_file` branch on line 35 of `Rakefile` does a `cp` when the filename matches `/neo/`).
- Contains: `Neo::Koan`, `Neo::Sensei`, `Neo::ThePath`, `Neo::Assertions`, `Neo::Color`, top-level helpers (`__`, `_n_`, `___`, `____`, `in_ruby_version`, `before_ruby_version`).
- Depends on: standard library only (`Gem::Version`, optional `win32console`).
- Used by: `koans/path_to_enlightenment.rb` (which `require`s every `about_*` file; each file `require`s `neo`, registering itself as a `Neo::Koan` subclass; the `END` block at the bottom of `neo.rb` then walks all subclasses in registration order).

**Project-test Layer:**
- Purpose: Verify this fork's additions (CLI, no-spoiler error formatting, consistency checks) without running the koans themselves.
- Location: `tests/`.
- Contains: minitest test cases.
- Depends on: minitest, `Rake.application.load_rakefile`, `Open3` for CLI subprocess tests.
- Used by: `rake test` (defined in `rakelib/test.rake`).

## Data Flow

### Primary Request Path: `rake` (or `rake walk_the_path`)

1. Default Rake task fires `walk_the_path` (`Rakefile:60`).
2. `walk_the_path` invokes `:gen` (`Rakefile:62`), which has a Rake file rule per `src/*` declaring `koans/<name>` depends on `[koans/, src/<name>]` (`Rakefile:112-116`).
3. For each out-of-date file, `Koans.make_koan_file` (`Rakefile:34`) opens the source and copies lines while toggling state on `#--` (skip) and `#++` (resume); inside `:copy` state it rewrites placeholder calls via `Koans.remove_solution` (`Rakefile:24-32`). Files matching `/neo/` are copied verbatim (so `koans/neo.rb` is byte-identical to `src/neo.rb`).
4. `cd PROB_DIR` then `ruby 'path_to_enlightenment.rb'` (`Rakefile:64-66`).
5. `koans/path_to_enlightenment.rb` adds `koans/` to `$LOAD_PATH` and `require`s every `about_*` file in order (`koans/path_to_enlightenment.rb:5-44`). Each `about_*` file does `require File.expand_path(File.dirname(__FILE__) + '/neo')` and declares `class AboutXxx < Neo::Koan ... end`.
6. `Neo::Koan.inherited` adds the subclass to `Neo::Koan.subclasses` (`src/neo.rb:481-483`). `Neo::Koan.method_added` collects every `def test_...` into `testmethods` (`src/neo.rb:485-487`).
7. After `path_to_enlightenment.rb` finishes loading, the `END` block at `src/neo.rb:557-562` runs `Neo::ThePath.new.walk`.
8. `Neo::ThePath#walk` instantiates `Neo::Sensei` and iterates over `Neo::Koan.subclasses` (i.e. registration order, which is `require` order from the manifest), then over each subclass's `testmethods` (i.e. source order). For every step it calls `koan.new(method_name, ...).meditate` (`src/neo.rb:534-554`).
9. `Neo::Koan#meditate` runs `setup`, `send(name)`, `teardown`, capturing any `StandardError` or `Neo::Sensei::FailedAssertionError` into `@failure` (`src/neo.rb:463-477`).
10. `Sensei#observe` increments `pass_count` on success or, on failure, records the pass count to `.path_progress`, stores the failed step, and `throw :neo_exit` to short-circuit the walk (`src/neo.rb:240-254`).
11. `Sensei#instruct` prints either the artistic end screen (path complete) or the encouragement + masked-failure message + zen statement + progress bar (`src/neo.rb:264-293`).

### Secondary Flow: `bin/koans walk`

1. `RubyKoansCLI.call` dispatches `"walk"` -> `walk` (`bin/koans:16-47`).
2. `walk` runs `rake gen` from the project root via `system` (`bin/koans:43-46`, `bin/koans:155-157`).
3. On success it shells out to `RbConfig.ruby` running `path_to_enlightenment.rb` from inside `koans/` (`bin/koans:46`, `bin/koans:163-169`). The classic Neo `END` block then takes over as in the primary flow.
4. The CLI returns the child process's exit status to the caller, which exits with the same code (`bin/koans:21-22`, `bin/koans:163-169`).

### Secondary Flow: `bin/koans watch` (and `rake watch` / `koans.watchr`)

1. `rake watch` simply shells out: `ruby 'bin/koans', 'watch'` (`Rakefile:73-75`).
2. `RubyKoansCLI.watch` regenerates once, prints the "Sensei is watching" banner, traps `INT` for a polite goodbye, then loops (`bin/koans:49-70`).
3. Each iteration computes `watched_files_signature` (sorted `[path, mtime, size]` tuples for `koans/*.{rb,txt}`), and when it changes it calls `walk_without_regenerating` (`bin/koans:159-161`, `185-190`).
4. Sleep duration comes from `KOANS_WATCH_INTERVAL` (default `0.5s`); clear-screen behaviour respects `KOANS_NO_CLEAR` (`bin/koans:175-183`).
5. `koans.watchr` (root) and `koans/koans.watchr` are alternative wrappers that the user runs under the `watchr` gem; both ultimately `system 'ruby bin/koans walk'` (or `../bin/koans walk` from inside `koans/`).

### Secondary Flow: `bin/koans list` / `next` / `hint`

1. `RubyKoansCLI.koan_steps` lazily loads the entire path with `NEO_DISABLE_END=true` (`bin/koans:206-227`). This loads `src/path_to_enlightenment.rb` from inside `src/`, which `require`s every `about_*` file but skips the `END` block in `neo.rb`, so no tests run.
2. `RubyKoansCLI.ordered_koans` reorders `Neo::Koan.subclasses` by re-reading the `require` order from `src/path_to_enlightenment.rb` (`bin/koans:229-248`). For each subclass it walks `testmethods` to produce a flat list of `{class_name, file, method_name}` steps.
3. `progress_count` parses `koans/.path_progress` (or `KOANS_PROGRESS_FILE` if set) and takes the last comma-separated entry's integer value (`bin/koans:200-204`).
4. `list` groups steps by file and prints `opened` / `next` / `waiting` per group (`bin/koans:72-88`, `250-279`).
5. `next` prints the current step's label + its file:line, derived by scanning the koan file for `def <method_name>` (`bin/koans:90-102`, `285-299`).
6. `hint` finds the comment block immediately above the current method definition in `src/<file>` and prints it without the answer (`bin/koans:104-124`, `301-318`).

### Secondary Flow: `bin/koans reset <file|all>`

1. `reset all` -> `rake regen` from the project root (`bin/koans:133-135`); this nukes `koans/` (`Rakefile:104-106`) and regenerates everything.
2. `reset <about_file>` normalises the target via `normalize_target_file` (rejects path traversal and unsafe characters: `\A[\w.\-]+\z`) (`bin/koans:320-327`), then re-runs `make_koan_file` for that single file (`bin/koans:126-153`, `329-345`).
3. The CLI's `make_koan_file`/`remove_solution` are line-for-line copies of the `Koans` module in the top-level `Rakefile`, kept so `bin/koans reset` works without invoking Rake for a single-file refresh.

### Secondary Flow: Internal `rake test`

1. `rakelib/test.rake` declares a `Rake::TestTask` over `tests/**/*_test.rb`.
2. `tests/test_helper.rb` requires `minitest/autorun`, `rake`, `stringio`, then `Rake.application.load_rakefile` so `check_test.rb` can invoke real Rake tasks.
3. `tests/koans_cli_test.rb` spawns `bin/koans` via `Open3.capture3`, asserting on stdout/stderr/exit status, with progress isolated per test by `KOANS_PROGRESS_FILE`.
4. `tests/neo_output_test.rb` requires `src/neo.rb` directly with `NEO_DISABLE_END=true` and asserts that `Sensei#guide_through_error` masks expected/actual values for `FailedAssertionError`.
5. `tests/check_test.rb` invokes `Rake::Task['check:asserts']` and `Rake::Task['check:abouts']` and asserts the captured stdout contains `OK`.

**State Management:**
- Source-of-truth state lives on disk: `src/*` (immutable input), `koans/*` (mutable working copy, the learner's edits live here), `koans/.path_progress` (append-only-ish ledger of pass counts).
- In-process state is module-level on `Neo::Koan` (`@subclasses`, `@test_methods`, `@tests_disabled`, `@test_pattern`) and on `Neo::Sensei` instances (per-walk).
- `bin/koans` memoises `@koan_steps` for the lifetime of a single CLI invocation (`bin/koans:207`).

## Key Abstractions

**`Neo::Koan` (test base class):**
- Purpose: Declarative test container; subclasses register themselves and their `test_*` methods automatically.
- Examples: `src/about_asserts.rb` (`class AboutAsserts < Neo::Koan`), every `src/about_*.rb`.
- Pattern: Self-registering test class via `inherited` hook + `method_added` filter (`src/neo.rb:480-531`). No external test framework required.

**`Neo::Sensei` (reporter / progress recorder):**
- Purpose: Watches each step, prints colorised observations, persists pass count, renders the end screen, masks the failing assertion's expected/actual values.
- Examples: `src/neo.rb:205-433`.
- Pattern: Stateful observer that `throw :neo_exit` on first failure to short-circuit the walk.

**`Neo::ThePath` (walker):**
- Purpose: Iterate `Neo::Koan.subclasses` in registration order and ask each koan to `meditate`.
- Examples: `src/neo.rb:534-554`.
- Pattern: Catch/throw-based early termination.

**`Neo::Assertions` (matchers):**
- Purpose: Replacement for minitest's matchers (`assert`, `assert_equal`, `assert_match`, `assert_raise`, `assert_nothing_raised`, etc.) so the koans never depend on a third-party assertion library.
- Examples: `src/neo.rb:147-203`.
- Pattern: Failure raises a custom `FailedAssertionError`, which `Sensei#guide_through_error` recognises so it can hide the answer.

**Solution placeholders (`__`, `___`, `____`, `_n_`):**
- Purpose: Visible blanks the learner replaces; in `src/`, the same identifiers are *function calls* with the answer as the argument (`__(2)`, `___(NoMethodError)`), so the source koans pass when run from `src/`.
- Examples: top-level definitions in `src/neo.rb:39-76`; usage in every `src/about_*.rb`.
- Pattern: The build pipeline strips the parenthesised argument (regex in `Koans.remove_solution`, `Rakefile:24-32`), turning `__(2)` into `__`, which the runtime defines as `"FILL ME IN"`.

**`#--` / `#++` solution markers:**
- Purpose: Mark blocks of canonical source that exist only to make the koans pass in `src/` and that must be omitted from the generated working copy.
- Examples: `src/about_asserts.rb:10-17`, `src/triangle.rb:18-23`, `src/about_dice_project.rb:9-17`.
- Pattern: State machine in `Koans.make_koan_file` (`Rakefile:38-53`) toggles `:copy`/`:skip`.

**`RubyKoansCLI` (command dispatcher):**
- Purpose: Single-file Ruby module that exposes the modern verbs (`walk`, `watch`, `list`, `next`, `hint`, `reset`, `help`).
- Examples: `bin/koans:8-376`.
- Pattern: Module-level singleton (`class << self`) with a `call(argv)` entry point.

## Entry Points

**`rake` / `rake walk_the_path` / `rake walk`:**
- Location: `Rakefile:57-70`.
- Triggers: User runs `rake` from the project root.
- Responsibilities: Generate koans, then walk the path until first failure.

**`rake gen` / `rake regen` / `rake clobber_koans`:**
- Location: `Rakefile:99-116`.
- Triggers: Explicit invocation, or as a dependency of `walk_the_path`.
- Responsibilities: Build/rebuild the `koans/` working copy from `src/`.

**`rake watch`:**
- Location: `Rakefile:72-75`.
- Triggers: User runs `rake watch`.
- Responsibilities: Delegates to `bin/koans watch`.

**`rake test` / `rake check`:**
- Location: `rakelib/test.rake:3-7`, `rakelib/checks.rake:47-48`.
- Triggers: `rake test` (this fork's project tests), `rake check` (consistency checks).
- Responsibilities: Run minitest suite under `tests/`; verify `path_to_enlightenment.rb` requires every about file and that asserts have `__`/`_n_` placeholders.

**`rake zip` / `rake package` / `rake upload`:**
- Location: `Rakefile:80-97`.
- Triggers: Distribution maintenance.
- Responsibilities: Build `download/rubykoans.zip` from `koans/*`; optionally `scp` it.

**`bin/koans <command>`:**
- Location: `bin/koans:1-378` (entry: `RubyKoansCLI.call(ARGV)` on line 378).
- Triggers: User runs `bin/koans walk|watch|list|next|hint|reset|help`.
- Responsibilities: Modern CLI dispatcher; every command exits with an explicit status code.

**`koans.watchr` (root) and `koans/koans.watchr`:**
- Location: `koans.watchr:1-11`, `koans/koans.watchr:1-11`.
- Triggers: User runs `watchr koans.watchr`.
- Responsibilities: Re-run `bin/koans walk` (or `../bin/koans walk` from inside `koans/`) on `*.rb` / `*.txt` changes.

**`koans/path_to_enlightenment.rb`:**
- Location: `koans/path_to_enlightenment.rb:1-44`.
- Triggers: Loaded by `ruby path_to_enlightenment.rb` from inside `koans/`; this is the actual program the runner spawns.
- Responsibilities: Add `koans/` to `$LOAD_PATH` and `require` every koan in canonical order; trigger the Neo `END` block.

**`koans/Rakefile`:**
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

**What happens:** Learner opens `src/about_strings.rb` (because their editor's grep found it first) and edits the source there.
**Why it's wrong:** `src/` is the build input. The next `rake gen`/`bin/koans walk` will not regenerate `koans/about_strings.rb` (it's already newer), so the learner sees no change in the path. Worse, `rake regen` will overwrite their edits.
**Do this instead:** Always edit inside `koans/`. The README explicitly says "Edit files inside +koans/+, not +src/+." (`README.rdoc:27-28`). For project tests, edit `src/*` (and remember to `rake regen`).

### Loading `src/neo.rb` without `NEO_DISABLE_END`

**What happens:** Some script `require`s `../src/neo` to introspect `Neo::Koan`, then exits — and the `END {}` block kicks in, running the entire path against whatever subclasses happened to be loaded.
**Why it's wrong:** It produces stray output, may clobber `.path_progress`, and may run only a partial suite.
**Do this instead:** Set `ENV['NEO_DISABLE_END'] = 'true'` *before* requiring `neo.rb`. See `bin/koans:222` and `tests/neo_output_test.rb:3`.

### Using `puts` directly in failure formatting

**What happens:** Adding a debug `puts failure.message` in `Neo::Sensei#guide_through_error`.
**Why it's wrong:** The whole point of `assert_failed?` branching at `src/neo.rb:362-371` is that for `FailedAssertionError` we must *not* leak the expected/actual values; otherwise the koan's answer appears in the terminal. `tests/neo_output_test.rb:16-29` enforces this.
**Do this instead:** Print location only for assertion failures; print full backtrace only for genuine runtime errors.

### Adding a koan file but forgetting `require` in `path_to_enlightenment.rb`

**What happens:** A new `src/about_foo.rb` exists, gets generated into `koans/about_foo.rb`, but is never run.
**Why it's wrong:** `Neo::ThePath#walk` only iterates registered subclasses. No `require`, no registration, no walk.
**Do this instead:** Add `require 'about_foo'` to `src/path_to_enlightenment.rb` in the appropriate position; `rake check:abouts` will warn if you forget.

### Skipping the placeholder convention

**What happens:** Author writes `assert_equal 2, 1 + 1` directly in `src/about_xxx.rb`.
**Why it's wrong:** After generation, the koan has the answer baked in — there's nothing for the learner to do. `rake check:asserts` (`rakelib/checks.rake:18-44`) flags asserts that lack `__` or `_n_`.
**Do this instead:** Use `assert_equal __(2), 1 + 1`, or the `#--`/`#++` block form for multi-line answers.

### Hand-writing files into `koans/` and committing them

**What happens:** Someone edits `koans/about_strings.rb` and commits it.
**Why it's wrong:** `.gitignore` line 10 (`koans/*`) excludes everything inside `koans/`. The commit will silently drop those files. `koans/` is generated, not source.
**Do this instead:** Make the change in `src/`, run `rake regen`, and commit only the `src/` change.

## Error Handling

**Strategy:** Distinguish *expected* failures (a koan failing because the learner has not yet filled it in) from *unexpected* failures (a typo, missing constant, runtime error). Both stop the walk, but they are formatted differently to avoid leaking answers.

**Patterns:**
- `Neo::Assertions::FailedAssertionError` is a custom subclass; `assert*` helpers `flunk` to it (`src/neo.rb:148-152`).
- `Neo::Koan#meditate` rescues `StandardError` *or* `Neo::Sensei::FailedAssertionError`, attaching the exception via `failed(ex)` (`src/neo.rb:463-477`).
- `Neo::Sensei#guide_through_error` branches on `assert_failed?`: assertion failures print only the file:line; everything else prints the exception class + message (`src/neo.rb:362-375`).
- `Neo::Sensei#observe` calls `throw :neo_exit`, caught by `Neo::ThePath#each_step`'s `catch(:neo_exit)` (`src/neo.rb:543-553`). This is the entire fail-fast mechanism.
- `bin/koans` commands always return an integer status; `RubyKoansCLI.call` `exit`s with it (`bin/koans:16-41`). `run` swallows `Dir.chdir`/`system` failures into a `1` (`bin/koans:163-169`).
- `bin/koans reset` rescues `ArgumentError` from `normalize_target_file` (path-traversal guard) (`bin/koans:150-153`).

## Cross-Cutting Concerns

**Logging:** Direct `puts` to `$stdout`. Colorisation through `Neo::Color` (which honours `NO_COLOR` and `ANSI_COLOR` env vars, `src/neo.rb:125-136`).

**Validation:** `rake check:abouts` (does every `src/about_*.rb` have a matching `require` in `path_to_enlightenment.rb`?) and `rake check:asserts` (does every `assert*` line carry a `__` placeholder?). Defined in `rakelib/checks.rake`.

**Authentication:** Not applicable.

**Configuration:** Environment variables only:
- `NEO_DISABLE_END` (skip the auto-walk `END` block)
- `SIMPLE_KOAN_OUTPUT` (boring vs artistic end screen, `src/neo.rb:93-95`)
- `NO_COLOR`, `ANSI_COLOR` (color toggling)
- `KOANS_WATCH_INTERVAL` (watcher poll interval, default `0.5`s)
- `KOANS_NO_CLEAR` (suppress screen clear in watch mode)
- `KOANS_PROGRESS_FILE` (override `.path_progress` location, used by tests)

**Internationalisation:** Single-language (English).

---

*Architecture analysis: 2026-05-07*
