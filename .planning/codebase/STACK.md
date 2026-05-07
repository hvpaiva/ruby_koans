# Technology Stack

**Analysis Date:** 2026-05-07

## Languages

**Primary:**
- Ruby (MRI/CRuby) — entire codebase. Source koans in `src/*.rb`, generated exercises in `koans/*.rb`, the Sensei runtime in `src/neo.rb`, the CLI in `bin/koans`, internal tests in `tests/`, and Rake tasks in `Rakefile` + `rakelib/*.rake`.

**Secondary:**
- JRuby (optional) — `src/about_java_interop.rb` is conditionally loaded only when running under JRuby. `src/path_to_enlightenment.rb:38-40` and `src/neo.rb:18-22` gate this with `in_ruby_version("jruby")`.
- ERB-free plain-text fixtures — `src/example_file.txt`, `src/GREED_RULES.txt` (no template engine; just `.txt` assets).

## Runtime

**Environment:**
- Ruby 3.2, 3.3, 3.4 — explicitly tested via the CI matrix in `.github/workflows/ci.yml:11`.
- Earlier versions of Ruby still survive in version-gating helpers (`src/neo.rb:18-35` defines `ruby_version?`, `in_ruby_version`, `before_ruby_version`), and `path_to_enlightenment.rb` still branches on `"2"`, `"3"`, `"4"`, `"2.7"`, `"jruby"`. CI does not exercise JRuby or Ruby 2.x.
- The CLI uses `RbConfig.ruby` (`bin/koans:172`) so it always re-invokes the active interpreter rather than hardcoding `ruby`.

**Package Manager:**
- Bundler — declared via `Gemfile` and locked by `Gemfile.lock`.
- `BUNDLED WITH 4.0.8` (`Gemfile.lock:25-26`).
- Lockfile: present (`Gemfile.lock`).
- `.gitignore:7` ignores `Gemfile.lock` (so the committed lockfile is intentional but no longer protected from local mutation by gitignore — see CONCERNS).

## Frameworks

**Core:**
- Rake 13.4.2 — task runner driving koan generation (`rake gen`, `rake regen`), the default walk (`rake walk_the_path`), packaging (`rake package`/`rake zip`), and deployment (`rake upload`). Defined in `Rakefile`, `rakelib/checks.rake`, `rakelib/run.rake`, `rakelib/test.rake`.
- Custom Neo test framework (`src/neo.rb`) — homegrown assertion + runner (`Neo::Koan`, `Neo::Sensei`, `Neo::Assertions`, `Neo::ThePath`, `Neo::Color`). Provides `assert`, `assert_equal`, `assert_match`, `assert_raise`, `assert_nothing_raised`, plus the meditation/karma narration. Auto-runs via an `END {}` block (`src/neo.rb:557-562`) unless `ENV['NEO_DISABLE_END'] == 'true'`.

**Testing:**
- Minitest 6.0.2 — used only for this fork's internal project tests under `tests/` (e.g. `tests/koans_cli_test.rb`, `tests/check_test.rb`, `tests/neo_output_test.rb`). Wired up via `Rake::TestTask` in `rakelib/test.rake`. `tests/test_helper.rb` requires `minitest/autorun`, `rake`, and `stringio`.
- Note: the koans themselves do **not** use Minitest. They run on the bespoke `Neo::Koan` framework in `src/neo.rb`.

**Build/Dev:**
- Rake's `FileList`/`pathmap` drive incremental koan generation (`Rakefile:10-11`, `Rakefile:112-116`).
- `zip` (system binary) — invoked by `rake package` to produce `download/rubykoans.zip` (`Rakefile:88`).
- `scp` (system binary) — invoked by `rake upload` to ship the zip to a remote host (`Rakefile:96`).
- `clear` (system binary) — invoked by the watcher and `bin/koans watch` to clear the terminal (`koans.watchr:2`, `bin/koans:182`).
- A custom CLI in `bin/koans` provides `walk`, `watch`, `list`, `next`, `hint`, `reset`, `help` (see `bin/koans:16-374`). It reuses the koan generation logic from `Rakefile` but reimplements `make_koan_file`/`remove_solution` locally (`bin/koans:329-354`).

## Key Dependencies

**Critical:**
- `rake` 13.4.2 — driver for the canonical workflow (`rake`, `rake walk`, `rake gen`, `rake regen`, `rake watch`, `rake test`, `rake check`).
- `minitest` 6.0.2 — internal test framework for this fork only.

**Transitive (from `Gemfile.lock`):**
- `drb` 2.2.3 — pulled in by minitest 6.x.
- `prism` 1.9.0 — pulled in by minitest 6.x.

**Infrastructure:**
- `rake/testtask` — used in `rakelib/test.rake` to define the `test` task scanning `tests/**/*_test.rb`.
- `rake/clean` — used in `Rakefile:4` to register `**/*.rbc` for clean.
- `fileutils`, `rbconfig`, `English`, `open3`, `tmpdir`, `stringio` — Ruby stdlib modules used by the CLI and tests (`bin/koans:4-6`, `tests/koans_cli_test.rb:3-5`, `tests/test_helper.rb:1-3`).
- `win32console` (optional, soft `require`) — `src/neo.rb:6-9` rescues `LoadError`. Not declared in `Gemfile`; only used when running on Windows under MRI to enable ANSI colors.

## Configuration

**Environment:**
- The project has **no `.env` files** and **no application-level secrets**. It runs entirely offline.
- Recognized environment variables:
  - `KOANS_PROGRESS_FILE` (`bin/koans:197`) — overrides the default progress file at `koans/.path_progress`.
  - `KOANS_WATCH_INTERVAL` (`bin/koans:176`) — float seconds between watch polls; defaults to `0.5`.
  - `KOANS_NO_CLEAR` (`bin/koans:182`) — when set, suppresses `system("clear")` during `bin/koans watch`.
  - `NEO_DISABLE_END` (`src/neo.rb:557`, `bin/koans:222`, `tests/neo_output_test.rb:3`) — disables the auto-run `END {}` so that `neo.rb` and the koan files can be loaded as libraries (used by tests and by `bin/koans list/next/hint`).
  - `SIMPLE_KOAN_OUTPUT` (`src/neo.rb:94`) — switches the end screen from the ASCII-art Sensei to a one-line message.
  - `NO_COLOR` (`src/neo.rb:126`) — standard `NO_COLOR` opt-out, disables ANSI colors.
  - `ANSI_COLOR` (`src/neo.rb:127-134`) — `t*`/`y*` forces colors on, anything else forces off; overrides TTY detection.

**Build:**
- `Gemfile`, `Gemfile.lock` — Bundler manifests.
- `Rakefile`, `rakelib/checks.rake`, `rakelib/run.rake`, `rakelib/test.rake` — Rake task definitions.
- `koans.watchr` — top-level watchr DSL script (`watch(...)` block); runs `ruby bin/koans walk` on koan file changes.
- `koans/Rakefile`, `koans/path_to_enlightenment.rb`, `koans/koans.watchr` — copies that ship alongside the generated exercise set so a learner can `cd koans && rake` standalone.
- No JS/TS, no webpack, no compile step. The "build" is the koan generator (`rake gen`), which strips solutions from `src/*.rb` into `koans/*.rb`.

## Platform Requirements

**Development:**
- Ruby 3.2, 3.3, or 3.4 with Bundler.
- Standard POSIX tooling for the full workflow: `clear`, `zip`, `scp`, `rm`, `cp`. Linux and macOS work without extra setup. Windows requires `win32console` for colored output; otherwise `Neo::Color.use_colors?` falls back to plain text (`src/neo.rb:125-144`).
- Optional: JRuby — only needed if the learner wants `about_java_interop.rb` to load.

**Production:**
- This is a learning project; there is no production runtime. The only "deployment" target is the static download artifact `download/rubykoans.zip`, historically pushed to `linode:sites/onestepback.org/download` via `rake upload` (`Rakefile:95-97`, `DEPLOYING:1-12`).

---

*Stack analysis: 2026-05-07*
