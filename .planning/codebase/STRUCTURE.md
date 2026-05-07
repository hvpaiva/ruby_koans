# Codebase Structure

**Analysis Date:** 2026-05-07

## Directory Layout

```
ruby_koans/
├── Rakefile                       # Top-level Rake driver (gen pipeline, walk, watch, zip, upload)
├── Gemfile                        # Two gems: minitest, rake
├── Gemfile.lock                   # (gitignored, but present locally)
├── README.rdoc                    # Learner-facing README; documents quick start, bin/koans verbs
├── DEPLOYING                      # Deployment notes (release / upload to onestepback.org)
├── koans.watchr                   # watchr config: re-run `bin/koans walk` on koans/ changes
├── ruby-koans-overhaul-context.md # Untracked working notes
├── .gitignore                     # Ignores koans/*, .path_progress, Gemfile.lock, *.rbc, etc.
│
├── bin/
│   └── koans                      # Modern CLI: walk/watch/list/next/hint/reset/help (executable, 378 lines)
│
├── src/                           # Canonical, answered source (build INPUT)
│   ├── neo.rb                     # Test runner ("Neo"): Koan, Sensei, ThePath, Assertions, Color
│   ├── path_to_enlightenment.rb   # Manifest: ordered `require` list defining the walk
│   ├── about_*.rb                 # 32 koan files, one topic each
│   ├── triangle.rb                # Free-form exercise stub used by about_triangle_project.rb
│   ├── GREED_RULES.txt            # Rules for the Greed dice game (used by about_extra_credit.rb)
│   ├── example_file.txt           # Fixture for koans that read a file
│   ├── koans.watchr               # Same watchr loop, scoped to inside-the-koans-dir use
│   └── Rakefile                   # Stripped Rakefile: `task :test => path_to_enlightenment.rb`
│
├── koans/                         # Generated, answer-stripped working copy (build OUTPUT)
│   │                              # GITIGNORED via `koans/*` in .gitignore
│   ├── neo.rb                     # Verbatim copy of src/neo.rb (filename matches /neo/ -> cp)
│   ├── path_to_enlightenment.rb   # Verbatim copy of src/path_to_enlightenment.rb
│   ├── about_*.rb                 # Stripped versions of src/about_*.rb (placeholders blanked)
│   ├── triangle.rb                # Stripped version of src/triangle.rb (TriangleError stays)
│   ├── GREED_RULES.txt            # Verbatim copy
│   ├── example_file.txt           # Verbatim copy
│   ├── koans.watchr               # Verbatim copy of src/koans.watchr
│   ├── Rakefile                   # Verbatim copy of src/Rakefile
│   ├── README.rdoc                # Copied from project root by Rakefile rule (Rakefile:108-110)
│   └── .path_progress             # Progress ledger, comma-separated pass counts (gitignored)
│
├── rakelib/                       # Auto-loaded by Rake; one file per concern
│   ├── checks.rake                # `check:abouts`, `check:asserts`, top-level `check`
│   ├── run.rake                   # Tiny alias: `runall => :run`
│   └── test.rake                  # `Rake::TestTask` over tests/**/*_test.rb
│
├── tests/                         # This fork's project tests (NOT learner-facing)
│   ├── test_helper.rb             # minitest/autorun + Rake.application.load_rakefile
│   ├── koans_cli_test.rb          # Spawns bin/koans via Open3; asserts on help/list/next/hint/reset
│   ├── neo_output_test.rb         # Verifies Sensei#guide_through_error never leaks the answer
│   └── check_test.rb              # Captures stdout from Rake::Task['check:*']
│
├── download/
│   └── rubykoans.zip              # Built by `rake zip`, scp'd by `rake upload`
│
├── keynote/
│   └── RubyKoans.key              # Apple Keynote presentation (historical)
│
└── .planning/
    └── codebase/                  # GSD codebase maps (this analysis lives here)
```

## Directory Purposes

**`bin/`:**
- Purpose: Executable entry points the user runs directly.
- Contains: `koans` (the modern CLI).
- Key files: `bin/koans` (executable, `RbConfig.ruby` shebang, 378 lines).

**`src/`:**
- Purpose: The canonical, answered version of every koan. This is what authors edit; the working copy is regenerated from here.
- Contains: 32 `about_*.rb` koan files, the `neo` runner, the `path_to_enlightenment` manifest, the `triangle.rb` exercise, two fixtures (`GREED_RULES.txt`, `example_file.txt`), a stripped Rakefile, and a `koans.watchr` config.
- Key files: `src/neo.rb`, `src/path_to_enlightenment.rb`, `src/about_asserts.rb` (the first stop on the path), `src/triangle.rb`.

**`koans/`:**
- Purpose: The student-facing working copy. Generated from `src/` by the Rake `:gen` task (or `bin/koans reset`), then edited by the learner.
- Contains: Mirrors `src/` 1-to-1 for `.rb`/`.txt` files, plus a copy of `README.rdoc` and a progress file `.path_progress`.
- Generated: Yes — by `Koans.make_koan_file` (`Rakefile:34-54`).
- Committed: No — `koans/*` is in `.gitignore` (line 10). It is rebuilt by anyone who runs `rake` for the first time.
- Key files: `koans/path_to_enlightenment.rb` (the actual program executed by every `walk`), `koans/.path_progress` (state).

**`rakelib/`:**
- Purpose: Auto-loaded Rake tasks; Rake imports every `*.rake` here on startup.
- Contains: One file per concern (`checks`, `run`, `test`).
- Key files: `rakelib/test.rake`, `rakelib/checks.rake`.

**`tests/`:**
- Purpose: Internal project tests for this fork (CLI, no-spoiler invariants, assert-completeness checks). Distinct from the koans themselves.
- Contains: `*_test.rb` files run by `rake test`, plus `test_helper.rb`.
- Key files: `tests/koans_cli_test.rb`, `tests/neo_output_test.rb`, `tests/check_test.rb`.

**`download/`:**
- Purpose: Distribution artifact directory.
- Contains: `rubykoans.zip` (built by `rake zip`).
- Generated: Yes — by `Rakefile:87-89`.
- Committed: Yes (the existing zip is checked in).

**`keynote/`:**
- Purpose: Historical presentation deck.
- Contains: `RubyKoans.key`.
- Committed: Yes.

**`.planning/codebase/`:**
- Purpose: GSD codebase analysis documents (ARCHITECTURE.md, STRUCTURE.md, etc.).
- Contains: Maps for tech / arch / quality / concerns focuses.
- Generated: Yes — by `/gsd-map-codebase`.
- Committed: Yes when the orchestrator commits them.

## Key File Locations

**Entry Points:**
- `bin/koans`: Modern CLI; `RubyKoansCLI.call(ARGV)` dispatches to `walk`/`watch`/`list`/`next`/`hint`/`reset`/`help`.
- `Rakefile`: Top-level Rake driver; default task is `walk_the_path`.
- `koans.watchr`: Root-level watchr config; runs `bin/koans walk` on `koans/*.{rb,txt}` changes.
- `koans/path_to_enlightenment.rb`: The actual Ruby program every walk executes.
- `koans/Rakefile`: Sub-Rakefile so a learner inside `koans/` can do `rake` and run the path.

**Configuration:**
- `Gemfile`: Two gems: `minitest`, `rake`.
- `Gemfile.lock`: Lockfile (gitignored — line 7 of `.gitignore`).
- `.gitignore`: Notably ignores `koans/*` (the entire generated tree) and `.path_progress`.

**Core Logic:**
- `src/neo.rb`: 562 lines. The `Neo` module: `Koan`, `Sensei`, `ThePath`, `Assertions`, `Color`. Top-level helpers `__`, `_n_`, `___`, `____`, `in_ruby_version`. `END {}` block at lines 557-562 auto-runs the walk unless `NEO_DISABLE_END=true`.
- `src/path_to_enlightenment.rb`: 44 lines. Ordered `require` manifest defining the path; `in_ruby_version` gates apply for keyword arguments, JRuby interop, pattern matching.
- `Rakefile`: 132 lines. The `Koans` module (lines 17-55), all task definitions, file rules per `src/*` (lines 112-116).
- `bin/koans`: 378 lines. `RubyKoansCLI` module with `walk`/`watch`/`list`/`next`/`hint`/`reset` plus duplicated generation helpers.

**Generation Pipeline:**
- `Rakefile:24-32`: `Koans.remove_solution` (regex-based placeholder stripper).
- `Rakefile:34-54`: `Koans.make_koan_file` (state-machine line copier with `#--`/`#++` markers).
- `bin/koans:329-354`: Duplicated `make_koan_file` / `remove_solution` for `bin/koans reset`.
- `Rakefile:99-106`: `:regen`, `:gen`, `:clobber_koans`.
- `Rakefile:112-116`: One Rake file rule per `src/*`.

**Testing:**
- `rakelib/test.rake`: Defines `rake test`.
- `tests/test_helper.rb`: Loads minitest + the project Rakefile.
- `tests/koans_cli_test.rb`: 78 lines; CLI integration tests (`Open3`-based).
- `tests/neo_output_test.rb`: 55 lines; `Neo::Sensei` output safety tests.
- `tests/check_test.rb`: 25 lines; runs `Rake::Task['check:*']` and asserts `OK`.

**Validation / Consistency:**
- `rakelib/checks.rake`: `check:abouts` and `check:asserts`. Top-level `rake check`.

## Naming Conventions

**Files:**
- Koans: `about_<topic>.rb` (snake_case, `about_` prefix is what `Dir['src/about_*.rb']` matches in `rakelib/checks.rake:6,23`).
- Project tests: `<noun>_test.rb` (e.g. `koans_cli_test.rb`, `neo_output_test.rb`); `Rake::TestTask` glob is `tests/**/*_test.rb` (`rakelib/test.rake:5`).
- Rake task files: `<concern>.rake`, one concern per file, auto-loaded from `rakelib/`.
- Watchr config: `koans.watchr` (top-level lowercase, no extension change between `src/` and `koans/`).
- Fixtures: descriptive snake_case (`example_file.txt`, `GREED_RULES.txt` — the latter intentionally upper-case to match in-game tone).

**Directories:**
- All lowercase, single-word: `bin/`, `src/`, `koans/`, `tests/`, `rakelib/`, `download/`, `keynote/`.

**Ruby identifiers:**
- Koan classes: `About<Topic>` (CamelCase, `About` prefix). Example: `class AboutAsserts < Neo::Koan` (`src/about_asserts.rb:6`).
- Test methods: `test_<lowercase_phrase>` (matches the default `Neo::Koan.test_pattern = /^test_/` at `src/neo.rb:524-526`).
- Helper methods: snake_case (`add_progress`, `walk_without_regenerating`, `koan_steps`).
- Modules: PascalCase (`Neo`, `RubyKoansCLI`, `Koans`).
- Constants: `SCREAMING_SNAKE_CASE` (`SRC_DIR`, `PROB_DIR`, `DOWNLOAD_DIR`, `ZIP_FILE`, `PROGRESS_FILE_NAME`, `KOANS_DIR`, `PATH_FILE`, `DEFAULT_PROGRESS_FILE`).
- Placeholders: `__`, `___`, `____`, `_n_` (deliberately weird-looking; defined as top-level methods in `src/neo.rb:39-76`).

**Solution markers (in source comments):**
- `#--` opens a "skip this in the generated koan" block.
- `#++` closes it.
- `# __` trailing comment is stripped by `Koans.remove_solution` (`Rakefile:30`).

## Where to Add New Code

**A new koan topic:**
- Primary code: `src/about_<topic>.rb` — start with `require File.expand_path(File.dirname(__FILE__) + '/neo')`, then `class About<Topic> < Neo::Koan`. Use `__(value)` / `_n_(value)` / `___(ExceptionClass)` for blanks; wrap multi-line answers with `#--` / `#++`.
- Manifest: add `require 'about_<topic>'` to `src/path_to_enlightenment.rb` in the desired position (order = walk order).
- Validation: `rake check:abouts` will warn if you forget the `require`; `rake check:asserts` will warn if any `assert` line lacks a placeholder.
- Generated copy: `rake gen` (or `bin/koans walk`) will produce `koans/about_<topic>.rb` automatically.

**A new free-form exercise (like `triangle.rb`):**
- Spec/tests: `src/about_<exercise>_project.rb` (and optionally `..._project_2.rb`).
- Implementation stub: `src/<exercise>.rb` — leave a stub method body wrapped in `#--`/`#++`. Keep any error class outside the stripped block.
- Wire into `src/path_to_enlightenment.rb`.
- The about-file must `require './<exercise>'` (note the `./` prefix — it works because `path_to_enlightenment.rb` does `cd koans/` before running).

**A new CLI verb on `bin/koans`:**
- Add a `when "<verb>"` branch in the dispatcher (`bin/koans:18-40`).
- Implement the verb as a `class << self` method.
- Add a one-liner to `help_text` (`bin/koans:356-374`).
- Test it with an Open3-based test in `tests/koans_cli_test.rb`.

**A new Rake task:**
- Pick a concern: `rakelib/checks.rake` (validation), `rakelib/run.rake` (running), `rakelib/test.rake` (test runners), or create a new `rakelib/<concern>.rake` (Rake auto-loads everything in `rakelib/`).
- Tasks that touch the generation pipeline (zip, regen, gen, walk) belong in the top-level `Rakefile`, not `rakelib/`.

**A new internal project test:**
- File: `tests/<thing>_test.rb`.
- Top of file: `require_relative "test_helper"`.
- Class: `class <Thing>Test < Minitest::Test` with `def test_*` methods.
- For tests that shell out to `bin/koans`, follow the `Open3.capture3` + `KOANS_PROGRESS_FILE` pattern in `tests/koans_cli_test.rb:11-24`.
- For tests that load `src/neo.rb`, set `ENV['NEO_DISABLE_END'] = 'true'` *before* the require (`tests/neo_output_test.rb:3`).

**A new placeholder convention (e.g. `_____`):**
- Add a top-level helper in `src/neo.rb` (alongside `__`, `_n_`, `___`).
- Add a regex to `Koans.remove_solution` (`Rakefile:24-32`) **and** the duplicate in `RubyKoansCLI.remove_solution` (`bin/koans:347-354`). Both must be updated.
- Add a check rule in `rakelib/checks.rake` if appropriate.

**A new fixture file:**
- Drop it in `src/<name>.txt` (or `.rb` if it's loadable code that should not be stripped).
- The Rake file rule (`Rakefile:112-116`) generates `koans/<name>` from every `src/*`.
- Files matching `/neo/` in basename get `cp`-ed verbatim; everything else goes through `make_koan_file`. If you have a non-koan file that must be byte-identical (like a `.txt` fixture), be aware that `make_koan_file` strips trailing `# __` comments and parenthesised placeholder calls, which is normally a no-op for plain text.

**Watcher behaviour change:**
- `bin/koans:185-190` (`watched_files_signature`) and `bin/koans:175-179` (`watch_interval`) are the knobs.
- `koans.watchr` (root) and `koans/koans.watchr` are independent loop drivers; both shell to `bin/koans walk`. Keep them in sync.

**Don't:**
- Don't edit `koans/*.rb` and commit it — `.gitignore` line 10 (`koans/*`) silently drops the change.
- Don't add new koans without a `require` in `path_to_enlightenment.rb`.
- Don't add `puts` of expected/actual values to the failure path in `Neo::Sensei` — `tests/neo_output_test.rb` will fail.

## Special Directories

**`koans/` (generated working copy):**
- Purpose: Where the learner edits.
- Generated: Yes (by `rake gen`). Files matching `/neo/` are copied verbatim; everything else is run through `Koans.make_koan_file`.
- Committed: No (`koans/*` in `.gitignore`). The repository works without it; first run regenerates.
- Note: Sub-`Rakefile` and sub-`koans.watchr` exist so a learner who `cd`s into `koans/` has working ergonomics there.

**`download/`:**
- Purpose: Distribution artifacts.
- Generated: Yes (`rake zip` writes `download/rubykoans.zip`).
- Committed: Yes (current zip is in the tree). `rake clobber_zip` removes it.

**`keynote/`:**
- Purpose: Historical artifact (presentation deck).
- Generated: No.
- Committed: Yes.

**`.planning/`:**
- Purpose: GSD planning + codebase-mapping output.
- Generated: Yes (by GSD commands).
- Committed: Yes (orchestrator commits these).

**`rakelib/`:**
- Purpose: Auto-loaded `.rake` files (Rake convention).
- Generated: No.
- Committed: Yes.

**`tests/`:**
- Purpose: Project's internal minitest suite (NOT the learner's koans).
- Generated: No.
- Committed: Yes.

---

*Structure analysis: 2026-05-07*
