# Codebase Structure

**Analysis Date:** 2026-05-07

## Directory Layout

```text
ruby_koans/
├── bin/                    # Executable CLI helper for walking, watching, listing, hinting, and resetting koans
│   └── koans               # `RubyKoansCLI` command entry point
├── src/                    # Canonical completed source used to generate learner exercises
│   ├── about_*.rb          # Topic lessons implemented as `About* < Neo::Koan`
│   ├── neo.rb              # Koan runtime, assertions, progress, and output
│   ├── path_to_enlightenment.rb # Ordered lesson loader
│   ├── triangle.rb         # Project exercise implementation source
│   ├── Rakefile            # Local path runner for source directory
│   └── *.txt               # Lesson support text files
├── koans/                  # Generated learner workspace derived from `src/`
│   ├── about_*.rb          # Learner-facing koan exercises with answers stripped
│   ├── neo.rb              # Copied runtime support
│   ├── path_to_enlightenment.rb # Generated ordered lesson loader
│   ├── .path_progress      # Default progress state file
│   └── README.rdoc         # Learner instructions copied from root README
├── tests/                  # Minitest regression suite for tooling and runtime behavior
├── rakelib/                # Additional Rake tasks loaded by root `Rakefile`
├── .github/workflows/      # GitHub Actions CI workflow
├── download/               # Package output target for `download/rubykoans.zip`
├── keynote/                # Presentation asset storage
├── .planning/codebase/     # GSD-generated codebase maps
├── Rakefile                # Main automation and generation task file
├── Gemfile                 # Ruby dependencies (`rake`, `minitest`)
├── Gemfile.lock            # Locked dependency versions
├── README.rdoc             # Project and learner documentation source
├── DEPLOYING               # Deployment notes
└── koans.watchr            # Legacy watchr integration
```

## Directory Purposes

**`bin/`:**
- Purpose: Holds executable user commands.
- Contains: The `bin/koans` Ruby script.
- Key files: `bin/koans`.
- Use this directory for new executable project commands that should be run from the repository root.

**`src/`:**
- Purpose: Canonical source for the complete koans and runtime.
- Contains: Topic files (`src/about_arrays.rb`), runtime support (`src/neo.rb`), path ordering (`src/path_to_enlightenment.rb`), exercise implementations (`src/triangle.rb`), text fixtures (`src/GREED_RULES.txt`, `src/example_file.txt`), and local runner files (`src/Rakefile`, `src/koans.watchr`).
- Key files: `src/neo.rb`, `src/path_to_enlightenment.rb`, `src/about_asserts.rb`, `src/triangle.rb`.
- Use this directory for new canonical koan lessons and source-only solutions.

**`koans/`:**
- Purpose: Generated learner workspace that users edit while solving koans.
- Contains: Stripped versions of `src/about_*.rb`, copied runtime files, copied support text, generated README, and progress state.
- Key files: `koans/neo.rb`, `koans/path_to_enlightenment.rb`, `koans/.path_progress`, `koans/README.rdoc`.
- Use generation commands rather than manual edits for structural changes to this directory.

**`tests/`:**
- Purpose: Regression tests for project tooling and runtime behavior.
- Contains: Minitest classes ending in `_test.rb` and shared setup in `tests/test_helper.rb`.
- Key files: `tests/test_helper.rb`, `tests/koans_cli_test.rb`, `tests/neo_output_test.rb`, `tests/check_test.rb`.
- Use this directory for tests of `bin/koans`, `Rakefile` behavior, `Neo` runtime behavior, and check tasks.

**`rakelib/`:**
- Purpose: Adds namespaced and support Rake tasks to the root Rake application.
- Contains: `rakelib/checks.rake`, `rakelib/test.rake`, `rakelib/run.rake`.
- Key files: `rakelib/checks.rake` for consistency checks, `rakelib/test.rake` for Minitest task configuration.
- Use this directory for additional Rake tasks that should load automatically with the root `Rakefile`.

**`.github/workflows/`:**
- Purpose: CI automation.
- Contains: GitHub Actions YAML workflows.
- Key files: `.github/workflows/ci.yml`.
- Use this directory for GitHub-hosted verification workflows.

**`download/`:**
- Purpose: Build output target for packaged koans.
- Contains: Generated archives such as `download/rubykoans.zip` when `rake package` runs.
- Key files: `download/rubykoans.zip` when present.
- Generated: Yes.

**`keynote/`:**
- Purpose: Stores presentation assets.
- Contains: `keynote/RubyKoans.key`.
- Key files: `keynote/RubyKoans.key`.
- Generated: No.

**`.planning/codebase/`:**
- Purpose: Stores GSD codebase maps consumed by planning and execution workflows.
- Contains: `ARCHITECTURE.md`, `STRUCTURE.md`, and other map documents when generated.
- Key files: `.planning/codebase/ARCHITECTURE.md`, `.planning/codebase/STRUCTURE.md`.
- Generated: Yes.

## Key File Locations

**Entry Points:**
- `bin/koans`: CLI entry point. Use for user-facing commands and command-flow changes.
- `Rakefile`: Main Rake entry point. Use for generation, packaging, and default path execution changes.
- `src/path_to_enlightenment.rb`: Direct source path runner and lesson-order definition.
- `koans/path_to_enlightenment.rb`: Generated learner path runner.
- `koans/Rakefile`: Local generated-koans runner that executes `path_to_enlightenment.rb`.
- `src/Rakefile`: Local source runner that executes `path_to_enlightenment.rb`.

**Configuration:**
- `Gemfile`: Runtime/test dependency declarations (`minitest`, `rake`).
- `Gemfile.lock`: Locked gem versions.
- `.github/workflows/ci.yml`: CI Ruby matrix and verification command.
- `.gitignore`: Git ignore configuration.
- `koans.watchr`: Root watchr integration that delegates to `ruby bin/koans walk`.
- `src/koans.watchr`: Source-directory watchr integration that delegates to `ruby ../bin/koans walk`.

**Core Logic:**
- `src/neo.rb`: Canonical koan runtime. Change assertions, path execution, progress, color, or failure guidance here.
- `koans/neo.rb`: Generated learner runtime. Keep synchronized from `src/neo.rb` through generation.
- `bin/koans`: CLI logic for commands, watch polling, progress introspection, hint extraction, and reset.
- `Rakefile`: Source-to-koans generation algorithm and main Rake tasks.
- `src/path_to_enlightenment.rb`: Ordered list of required koan topic files.
- `src/about_*.rb`: Canonical lesson content.
- `src/triangle.rb`: Canonical triangle project implementation.

**Testing:**
- `tests/test_helper.rb`: Minitest, Rake, and StringIO setup; loads the root Rakefile.
- `tests/koans_cli_test.rb`: CLI subprocess behavior for help, list, next, hint, and reset validation.
- `tests/neo_output_test.rb`: Runtime output and assertion behavior for `Neo::Sensei` and `Neo::Koan`.
- `tests/check_test.rb`: Rake check task coverage.
- `rakelib/test.rake`: Rake test task configuration for `tests/**/*_test.rb`.
- `rakelib/checks.rake`: Check implementation exercised by tests and CI.

**Documentation and Support Assets:**
- `README.rdoc`: Root documentation source copied to `koans/README.rdoc`.
- `koans/README.rdoc`: Learner-facing generated copy.
- `DEPLOYING`: Deployment notes.
- `src/GREED_RULES.txt` and `koans/GREED_RULES.txt`: Scoring project support text.
- `src/example_file.txt` and `koans/example_file.txt`: File IO lesson support text.

## Naming Conventions

**Files:**
- Koan topic files use `about_<topic>.rb`: `src/about_arrays.rb`, `src/about_keyword_arguments.rb`, `koans/about_triangle_project_2.rb`.
- Project exercise files use concise snake_case names without `about_`: `src/triangle.rb`, `koans/triangle.rb`.
- Test files use `<subject>_test.rb`: `tests/koans_cli_test.rb`, `tests/neo_output_test.rb`, `tests/check_test.rb`.
- Rake extension files use `<task_area>.rake`: `rakelib/checks.rake`, `rakelib/test.rake`, `rakelib/run.rake`.
- Generated and canonical pairs keep identical basenames between `src/` and `koans/`: `src/about_hashes.rb` maps to `koans/about_hashes.rb`.

**Directories:**
- Top-level directories use lowercase names: `src/`, `koans/`, `tests/`, `rakelib/`, `download/`, `keynote/`.
- GitHub workflow configuration follows GitHub's conventional path: `.github/workflows/`.
- GSD planning artifacts live under `.planning/codebase/`.

**Classes and Modules:**
- Topic classes use `AboutCamelCase` and inherit from `Neo::Koan`: `AboutAsserts` in `src/about_asserts.rb`, `AboutTriangleProject` in `src/about_triangle_project.rb`.
- Runtime classes live under the `Neo` namespace: `Neo::Sensei`, `Neo::Koan`, `Neo::ThePath` in `src/neo.rb`.
- CLI singleton logic lives under `RubyKoansCLI` in `bin/koans`.

**Methods:**
- Koan steps use `test_<description>` so `Neo::Koan.method_added` collects them by default: `test_assert_truth` in `src/about_asserts.rb`, `test_equilateral_triangles_have_equal_sides` in `src/about_triangle_project.rb`.
- CLI command methods use command names directly: `walk`, `watch`, `list`, `next_step`, `hint`, `reset` in `bin/koans`.
- Predicate methods end with `?`: `Neo.simple_output`, `Neo::Sensei#failed?`, `Neo::Color.use_colors?`, `RubyKoansCLI.group_status` uses string status values.

## Where to Add New Code

**New Koan Topic:**
- Primary code: Add `src/about_<topic>.rb`.
- Runtime order: Add `require 'about_<topic>'` to `src/path_to_enlightenment.rb`.
- Generated learner copy: Run `rake gen` to create `koans/about_<topic>.rb`.
- Tests/checks: Run `rake check`; `rakelib/checks.rake` expects every `src/about_*.rb` to be required.
- Pattern: Define `class AboutTopic < Neo::Koan` and `def test_<behavior>` methods, as in `src/about_asserts.rb`.

**New Project Exercise Supporting a Koan:**
- Primary code: Add implementation source under `src/<exercise>.rb`, following `src/triangle.rb`.
- Lesson code: Require it from the topic file with a current-directory-relative require, following `src/about_triangle_project.rb:4`.
- Generated learner copy: Let `rake gen` copy `src/<exercise>.rb` to `koans/<exercise>.rb`.
- Tests: Add regression coverage only if the project tooling or hidden source behavior needs protection; learner-facing assertions belong in `src/about_<topic>.rb`.

**New CLI Command:**
- Implementation: Add dispatch branch in `bin/koans:19` and a singleton method in `RubyKoansCLI`.
- Help text: Update `bin/koans:356`.
- Tests: Add subprocess coverage to `tests/koans_cli_test.rb` using `run_cli`.
- State/config: Prefer environment-variable configuration only when commands must be scriptable, following `KOANS_PROGRESS_FILE` in `bin/koans:196`.

**New Rake Task:**
- Implementation: Add task to `rakelib/<area>.rake` for modular tasks or to root `Rakefile` for generation/package tasks.
- Tests: Add Minitest coverage in `tests/check_test.rb` or a new `tests/<area>_test.rb` when behavior matters.
- CI: Include the task in `.github/workflows/ci.yml` only when every PR must run it.

**Runtime Behavior Change:**
- Primary code: Change `src/neo.rb`.
- Generated copy: Run `rake gen` so `koans/neo.rb` matches.
- Tests: Add focused coverage to `tests/neo_output_test.rb` or a new runtime test file.
- Tooling load: Preserve `NEO_DISABLE_END` semantics for any new definition-loading behavior.

**Generation Rule Change:**
- Primary code: Update both `Koans.remove_solution` / `Koans.make_koan_file` in `Rakefile` and the matching CLI generation helpers in `bin/koans`.
- Tests: Add or update CLI reset/generation tests in `tests/koans_cli_test.rb` and check-task tests if applicable.
- Generated copy: Run `rake regen` only when intentionally replacing learner-facing generated files.

**New Tests:**
- Location: Add `tests/<subject>_test.rb`.
- Setup: Require `tests/test_helper.rb` with `require_relative "test_helper"`.
- CLI tests: Use `Open3.capture3` through the existing `run_cli` helper pattern in `tests/koans_cli_test.rb`.
- Runtime tests: Set `ENV['NEO_DISABLE_END'] = 'true'` before requiring `src/neo.rb`, as in `tests/neo_output_test.rb`.

**Utilities:**
- CLI-only helpers: Keep inside `RubyKoansCLI` in `bin/koans`.
- Runtime helpers for koan execution: Keep inside `Neo` modules/classes in `src/neo.rb`.
- Rake-only helpers: Keep inside the `Koans` module in `Rakefile` or inside `rakelib/*.rake` namespaces.
- Avoid adding a generic utility directory unless code is shared by at least two existing layers.

## Special Directories

**`koans/`:**
- Purpose: Learner workspace generated from `src/`.
- Generated: Yes.
- Committed: Yes.
- Safe modification: Learners edit answers in `koans/`; maintainers change source structure in `src/` and regenerate.

**`src/`:**
- Purpose: Canonical source of truth for lessons and runtime.
- Generated: No.
- Committed: Yes.
- Safe modification: Use solution markers `#--` and `#++` for source-only answers that must disappear from generated koans.

**`download/`:**
- Purpose: Package output directory for `download/rubykoans.zip`.
- Generated: Yes.
- Committed: Directory may exist; package artifacts are build outputs.
- Safe modification: Let `rake package` create archive outputs.

**`rakelib/`:**
- Purpose: Auto-loaded Rake task extensions.
- Generated: No.
- Committed: Yes.
- Safe modification: Keep task names explicit and add tests for task behavior that affects CI.

**`tests/`:**
- Purpose: Minitest regression suite for project behavior, not learner koan answers.
- Generated: No.
- Committed: Yes.
- Safe modification: Test public command behavior, runtime output contracts, and Rake task checks.

**`.github/workflows/`:**
- Purpose: CI definitions.
- Generated: No.
- Committed: Yes.
- Safe modification: Keep the verification command aligned with available Rake tasks, currently `bundle exec rake test check`.

**`.planning/codebase/`:**
- Purpose: GSD codebase analysis documents.
- Generated: Yes.
- Committed: Depends on project workflow.
- Safe modification: Update through codebase mapping workflows rather than hand-editing stale architectural claims.

---

*Structure analysis: 2026-05-07*
