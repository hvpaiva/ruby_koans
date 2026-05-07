<!-- refreshed: 2026-05-07 -->
# Architecture

**Analysis Date:** 2026-05-07

## System Overview

```text
┌─────────────────────────────────────────────────────────────┐
│                  User Commands / Automation                  │
├──────────────────┬──────────────────┬───────────────────────┤
│   `bin/koans`    │    `Rakefile`     │  `.github/workflows/` │
│  CLI commands    │  classic tasks    │   CI test/check flow  │
└────────┬─────────┴────────┬─────────┴──────────┬────────────┘
         │                  │                     │
         ▼                  ▼                     ▼
┌─────────────────────────────────────────────────────────────┐
│                 Source-to-exercise generation                │
│ `src/*` ──remove solutions──▶ `koans/*`                      │
│ `Rakefile`, `bin/koans`                                      │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│                 Koan runtime and lesson suite                │
│ `koans/path_to_enlightenment.rb` loads `koans/about_*.rb`    │
│ `koans/neo.rb` records progress and stops on first failure   │
└─────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| CLI command dispatcher | Parses `walk`, `watch`, `list`, `next`, `hint`, `reset`, and `help`; returns process exit codes. | `bin/koans:15` |
| Koan generator | Copies `src/` files into `koans/` while stripping solution-only regions and answer arguments. | `Rakefile:17`, `bin/koans:329` |
| Rake orchestration | Defines default `rake` flow, packaging, regeneration, checks, and source-run tasks. | `Rakefile:57`, `Rakefile:99`, `Rakefile:118` |
| Path loader | Defines the ordered lesson sequence by requiring topic files from the current load path. | `src/path_to_enlightenment.rb:3`, `koans/path_to_enlightenment.rb:3` |
| Koan runtime | Supplies fill-in placeholders, assertions, progress tracking, failure output, and test discovery. | `src/neo.rb:15`, `src/neo.rb:91` |
| Koan classes | Hold one topic per `About*` class, with each `test_*` method becoming one step on the path. | `src/about_asserts.rb:6`, `src/about_triangle_project.rb:6` |
| Project exercises | Provide code that learners complete outside the `About*` classes. | `src/triangle.rb:16`, `koans/triangle.rb:16` |
| Consistency checks | Verifies path completeness and missing answer placeholders before CI passes. | `rakelib/checks.rake:1` |
| Minitest suite | Tests CLI behavior, output behavior, and check tasks. | `tests/koans_cli_test.rb:7`, `tests/neo_output_test.rb:6`, `tests/check_test.rb:3` |
| CI pipeline | Runs tests and checks against supported Ruby versions. | `.github/workflows/ci.yml:5` |

## Pattern Overview

**Overall:** Generated exercise suite with a small custom test runner.

**Key Characteristics:**
- Treat `src/` as canonical lesson source and `koans/` as the learner-editable generated workspace.
- Use Ruby file loading and class hooks instead of a conventional test framework for koan execution.
- Run one ordered path and stop at the first failing koan to preserve the learning loop.
- Keep tool-facing regression tests in `tests/` with Minitest, separate from learner koans in `src/` and `koans/`.
- Keep command automation thin: `bin/koans` and `Rakefile` delegate the lesson runtime to `path_to_enlightenment.rb` and `neo.rb`.

## Layers

**Command Layer:**
- Purpose: Provide user-facing and automation-facing entry points.
- Location: `bin/koans`, `Rakefile`, `koans/Rakefile`, `src/Rakefile`, `koans.watchr`, `.github/workflows/ci.yml`.
- Contains: CLI command parsing, Rake tasks, watch loops, CI workflow configuration.
- Depends on: `src/`, `koans/`, `rake`, `minitest`, Ruby stdlib (`FileUtils`, `RbConfig`, `Open3`, `Tmpdir`).
- Used by: Learners running `bin/koans walk`, maintainers running `rake test check`, CI running `bundle exec rake test check`.

**Generation Layer:**
- Purpose: Produce clean exercise files from complete source files.
- Location: `Rakefile:20`, `Rakefile:34`, `bin/koans:329`, `bin/koans:347`.
- Contains: `Koans.remove_solution`, `Koans.make_koan_file`, `RubyKoansCLI.make_koan_file`, `RubyKoansCLI.remove_solution`.
- Depends on: Source files in `src/`, destination directory `koans/`, solution markers `#--` and `#++`, placeholders `__`, `___`, `____`, `_n_`.
- Used by: `rake gen`, `rake regen`, `rake`, `bin/koans walk`, `bin/koans reset`, `bin/koans watch`.

**Lesson Definition Layer:**
- Purpose: Define lesson order and each koan topic.
- Location: `src/path_to_enlightenment.rb`, `koans/path_to_enlightenment.rb`, `src/about_*.rb`, `koans/about_*.rb`.
- Contains: Ordered `require` statements, Ruby-version-gated koans, `About* < Neo::Koan` classes, `test_*` methods.
- Depends on: `neo.rb` loaded by each topic file, local project files such as `src/triangle.rb`.
- Used by: `Neo::ThePath`, `RubyKoansCLI.koan_steps`, Rake tasks that run `path_to_enlightenment.rb`.

**Runtime Layer:**
- Purpose: Execute koan steps, capture failures, format feedback, and remember progress.
- Location: `src/neo.rb`, `koans/neo.rb`.
- Contains: `Neo::Assertions`, `Neo::Sensei`, `Neo::Koan`, `Neo::ThePath`, `Neo::Color`, fill-in helper methods.
- Depends on: Ruby `END` hook, `ARGV`, environment variables (`NEO_DISABLE_END`, `SIMPLE_KOAN_OUTPUT`, `NO_COLOR`, `ANSI_COLOR`), `.path_progress` file.
- Used by: Every `about_*.rb` class and every path execution.

**Regression Test Layer:**
- Purpose: Protect project tooling and runtime behavior without using the koan runner.
- Location: `tests/test_helper.rb`, `tests/*_test.rb`, `rakelib/test.rake`.
- Contains: Minitest tests, subprocess CLI assertions, Rake task assertions.
- Depends on: `minitest`, `rake`, Ruby stdlib, `bin/koans`, `src/neo.rb`.
- Used by: `rake test`, `bundle exec rake test`, CI workflow.

## Data Flow

### Primary Request Path

1. User runs the default task or CLI (`Rakefile:57`, `bin/koans:16`).
2. Generation runs before execution (`Rakefile:62`, `bin/koans:43`).
3. Source files from `src/` are copied to `koans/` with solutions stripped (`Rakefile:112`, `Rakefile:114`, `bin/koans:335`).
4. Execution changes into `koans/` and runs `path_to_enlightenment.rb` (`Rakefile:63`, `bin/koans:46`).
5. `koans/path_to_enlightenment.rb` adds its directory to `$LOAD_PATH` and requires topic files in order (`koans/path_to_enlightenment.rb:3`).
6. Each topic file requires `koans/neo.rb`, then defines an `About* < Neo::Koan` class (`koans/about_asserts.rb:4`, `koans/about_asserts.rb:6`).
7. `Neo::Koan.inherited` collects each koan class and `Neo::Koan.method_added` collects `test_*` methods (`koans/neo.rb:481`, `koans/neo.rb:485`).
8. The `END` block invokes `Neo::Koan.command_line(ARGV)` and `Neo::ThePath.new.walk` (`koans/neo.rb:557`).
9. `Neo::ThePath#each_step` instantiates each test method in order and yields it to `Neo::Sensei` (`koans/neo.rb:543`).
10. `Neo::Koan#meditate` runs setup, the test method, and teardown, then stores the failure if one occurs (`koans/neo.rb:463`).
11. `Neo::Sensei#observe` increments progress for passing steps or records the first failing step and throws `:neo_exit` (`koans/neo.rb:240`).
12. `Neo::Sensei#instruct` prints either guidance for the first failure or the completion screen (`koans/neo.rb:264`).

### CLI Introspection Flow

1. User runs `bin/koans list`, `bin/koans next`, or `bin/koans hint` (`bin/koans:24`, `bin/koans:27`, `bin/koans:29`).
2. `RubyKoansCLI.koan_steps` loads source definitions with `NEO_DISABLE_END=true` so the runtime `END` hook does not walk the path (`bin/koans:206`, `bin/koans:221`).
3. The CLI reads the ordered require list from `src/path_to_enlightenment.rb` (`bin/koans:238`).
4. The CLI matches loaded `Neo::Koan.subclasses` to source file names using method source locations (`bin/koans:229`, `bin/koans:242`).
5. `list` groups steps by koan file and prints gate status based on `.path_progress` (`bin/koans:72`, `bin/koans:250`, `bin/koans:268`).
6. `next` prints the current step label and line location (`bin/koans:90`, `bin/koans:281`, `bin/koans:285`).
7. `hint` scans comments immediately above the source method and excludes marker comments (`bin/koans:104`, `bin/koans:301`).

### Reset Flow

1. User runs `bin/koans reset <about_file|all>` (`bin/koans:126`).
2. `reset all` delegates to `rake regen` in the project root (`bin/koans:133`).
3. Single-file reset normalizes a safe file name and maps `src/<file>` to `koans/<file>` (`bin/koans:137`, `bin/koans:320`).
4. The CLI regenerates only that file with the same stripping algorithm used by `rake gen` (`bin/koans:146`, `bin/koans:329`).

**State Management:**
- Progress state lives in `koans/.path_progress` by default and can be redirected with `KOANS_PROGRESS_FILE` (`src/neo.rb:217`, `bin/koans:196`).
- Runtime discovery state lives in class instance variables on `Neo::Koan` (`src/neo.rb:510`, `src/neo.rb:516`, `src/neo.rb:520`, `src/neo.rb:524`).
- CLI step metadata is memoized in `RubyKoansCLI.koan_steps` (`bin/koans:206`).
- Generation state is file-system state: canonical inputs in `src/`, generated outputs in `koans/`, package output in `download/rubykoans.zip` (`Rakefile:6`, `Rakefile:7`, `Rakefile:13`).

## Key Abstractions

**`Neo::Koan`:**
- Purpose: Base class for all koan topic classes and registry for ordered test methods.
- Examples: `src/neo.rb:436`, `src/about_asserts.rb:6`, `src/about_triangle_project.rb:6`.
- Pattern: Hook-based registry via `inherited` and `method_added`; instance execution via `meditate`.

**`Neo::Sensei`:**
- Purpose: Observer and reporter for path execution, including progress recording and failure guidance.
- Examples: `src/neo.rb:205`, `src/neo.rb:240`, `src/neo.rb:264`.
- Pattern: Stateful runner collaborator; `Neo::ThePath` delegates pass/fail interpretation to it.

**`Neo::ThePath`:**
- Purpose: Iterates through every collected koan method in the required order and stops on first failure.
- Examples: `src/neo.rb:534`, `src/neo.rb:543`.
- Pattern: Enumerator-like orchestration using `catch(:neo_exit)` and `throw :neo_exit`.

**Fill-in placeholders:**
- Purpose: Represent answers that generation strips from learner files while preserving complete source files.
- Examples: `src/neo.rb:39`, `src/neo.rb:48`, `src/neo.rb:57`, `src/about_asserts.rb:36`.
- Pattern: Top-level helper methods available to all koan files after `neo.rb` is required.

**Solution markers:**
- Purpose: Separate hidden source-only implementation from learner-visible exercise content.
- Examples: `src/about_asserts.rb:10`, `src/about_asserts.rb:13`, `src/triangle.rb:18`, `src/triangle.rb:23`.
- Pattern: Line-state stripping in `Koans.make_koan_file` and `RubyKoansCLI.make_koan_file`.

**`RubyKoansCLI`:**
- Purpose: Command facade around generation, execution, introspection, hints, and reset.
- Examples: `bin/koans:8`, `bin/koans:16`, `bin/koans:356`.
- Pattern: Module singleton (`class << self`) with private-by-convention command helpers.

## Entry Points

**Default Rake path walk:**
- Location: `Rakefile:57`.
- Triggers: `rake` or `bundle exec rake` from project root.
- Responsibilities: Invoke `gen`, change into `koans/`, run `path_to_enlightenment.rb`.

**CLI path walk:**
- Location: `bin/koans:43`.
- Triggers: `bin/koans`, `bin/koans walk`, `bin/koans run`, `bin/koans meditate`.
- Responsibilities: Generate koans and run the generated path with the active Ruby executable.

**CLI watch mode:**
- Location: `bin/koans:49`.
- Triggers: `bin/koans watch` or `rake watch` (`Rakefile:73`).
- Responsibilities: Regenerate before watching, rerun the path when `koans/*.{rb,txt}` changes, handle `Ctrl-C`.

**CLI metadata commands:**
- Location: `bin/koans:72`, `bin/koans:90`, `bin/koans:104`.
- Triggers: `bin/koans list`, `bin/koans next`, `bin/koans hint`.
- Responsibilities: Load source definitions without runtime execution and report progress-aware guidance.

**CLI reset command:**
- Location: `bin/koans:126`.
- Triggers: `bin/koans reset all` or `bin/koans reset about_hashes`.
- Responsibilities: Regenerate all koans through Rake or regenerate one safe target file.

**Direct path execution:**
- Location: `src/path_to_enlightenment.rb`, `koans/path_to_enlightenment.rb`.
- Triggers: `ruby path_to_enlightenment.rb` inside `src/` or `koans/`.
- Responsibilities: Load koans in order and let `neo.rb` run the `END` hook.

**Regression tests:**
- Location: `rakelib/test.rake:3`, `tests/test_helper.rb:1`.
- Triggers: `rake test`, `bundle exec rake test`, CI workflow.
- Responsibilities: Run Minitest files matching `tests/**/*_test.rb`.

**Consistency checks:**
- Location: `rakelib/checks.rake:48`.
- Triggers: `rake check`, CI workflow.
- Responsibilities: Compare `src/about_*.rb` count to `src/path_to_enlightenment.rb` requires and detect assertions missing placeholders.

## Architectural Constraints

- **Threading:** The runtime is single-process and single-threaded. `bin/koans watch` uses a polling loop with `sleep` rather than threads (`bin/koans:61`).
- **Global state:** `src/neo.rb` defines top-level helper methods, modifies `Object`, modifies `String`, and uses `Neo::Koan` class instance variables (`src/neo.rb:39`, `src/neo.rb:66`, `src/neo.rb:78`, `src/neo.rb:510`).
- **Runtime hook:** `neo.rb` executes the path from an `END` block unless `NEO_DISABLE_END` is set to `true` (`src/neo.rb:557`, `bin/koans:221`). Set `NEO_DISABLE_END=true` before loading `src/neo.rb` for tooling or tests that inspect definitions.
- **Working directory sensitivity:** Path execution expects the current directory to be `src/` or `koans/` because project koans use relative requires such as `require './triangle'` (`src/about_triangle_project.rb:4`, `Rakefile:63`, `bin/koans:46`).
- **Generated file contract:** Do not edit `src/` as learner progress. Learner answers live in `koans/`; `rake regen` and `bin/koans reset all` replace generated files (`Rakefile:99`, `bin/koans:133`).
- **Circular imports:** No circular require chain is detected in the core path. Topic files require `neo.rb`; `path_to_enlightenment.rb` requires topic files; `neo.rb` does not require topic files (`src/path_to_enlightenment.rb:5`, `src/about_asserts.rb:4`, `src/neo.rb`).
- **Ruby version gates:** Some lessons load only under matching Ruby engines or versions (`src/path_to_enlightenment.rb:15`, `src/path_to_enlightenment.rb:38`, `src/path_to_enlightenment.rb:41`).

## Anti-Patterns

### Editing generated and canonical files interchangeably

**What happens:** Applying the same feature or lesson change directly to both `src/about_*.rb` and `koans/about_*.rb` bypasses generation.
**Why it's wrong:** `koans/` is derived from `src/`; manual edits drift from the stripping rules in `Rakefile:34` and `bin/koans:329`.
**Do this instead:** Change canonical lesson source in `src/`, then run `rake gen` or use `bin/koans reset <file>` to regenerate the matching `koans/` file (`Rakefile:103`, `bin/koans:126`).

### Loading koan definitions without disabling the `END` hook

**What happens:** Tooling that calls `load 'src/path_to_enlightenment.rb'` runs the path at process exit.
**Why it's wrong:** The `END` block in `src/neo.rb:557` treats definition loading as a full koan run and can print output or exit unexpectedly.
**Do this instead:** Set `ENV['NEO_DISABLE_END'] = 'true'` before loading definitions, as `bin/koans:221` and `tests/neo_output_test.rb:3` do.

### Adding topic files without updating the path

**What happens:** A new `src/about_new_topic.rb` exists but is not required in `src/path_to_enlightenment.rb`.
**Why it's wrong:** `Neo::Koan.subclasses` only includes loaded classes, so the path and CLI never see the new topic.
**Do this instead:** Add a `require 'about_new_topic'` line to `src/path_to_enlightenment.rb` and let `rake check` validate count parity (`rakelib/checks.rake:4`).

### Using absolute process assumptions inside koan files

**What happens:** A koan file assumes project root paths while execution runs inside `koans/` or `src/`.
**Why it's wrong:** The path runner changes directory before executing (`Rakefile:63`, `bin/koans:164`), so root-relative file access can fail.
**Do this instead:** Use file-local paths or current-directory-relative dependencies matching existing examples like `require File.expand_path(File.dirname(__FILE__) + '/neo')` and `require './triangle'` (`src/about_asserts.rb:4`, `src/about_triangle_project.rb:4`).

## Error Handling

**Strategy:** Koan failures are expected control flow. Assertion failures hide answers; non-assertion runtime failures print class and message context.

**Patterns:**
- Raise `Neo::Assertions::FailedAssertionError` through `flunk` for assertion failures (`src/neo.rb:147`, `src/neo.rb:150`).
- Capture `StandardError` and assertion failures inside `Neo::Koan#meditate` so the path can continue to reporting (`src/neo.rb:463`).
- Use `throw :neo_exit` to stop the path after the first failing step (`src/neo.rb:252`, `src/neo.rb:544`).
- Return numeric CLI status codes from command methods and call `exit` in the dispatcher (`bin/koans:16`, `bin/koans:21`).
- Rescue invalid watch intervals and reset targets with safe defaults or user-facing errors (`bin/koans:175`, `bin/koans:150`).

## Cross-Cutting Concerns

**Logging:** User-facing output uses `puts`, `warn`, and terminal coloring through `Neo::Color` (`src/neo.rb:98`, `bin/koans:33`, `bin/koans:36`).
**Validation:** File-name validation for reset is explicit in `bin/koans:320`; consistency validation lives in `rakelib/checks.rake`; koan assertions live in `Neo::Assertions` (`src/neo.rb:147`).
**Authentication:** Not applicable; the repository has no authentication layer.
**Configuration:** Environment variables control output and progress behavior: `SIMPLE_KOAN_OUTPUT`, `NO_COLOR`, `ANSI_COLOR`, `NEO_DISABLE_END`, `KOANS_WATCH_INTERVAL`, `KOANS_NO_CLEAR`, and `KOANS_PROGRESS_FILE` (`src/neo.rb:93`, `src/neo.rb:125`, `bin/koans:175`, `bin/koans:196`).
**Packaging:** `Rakefile` creates `download/rubykoans.zip` from `koans/*` and includes upload support (`Rakefile:80`, `Rakefile:95`).

---

*Architecture analysis: 2026-05-07*
