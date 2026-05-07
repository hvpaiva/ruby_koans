# Technology Stack

**Analysis Date:** 2026-05-07

## Languages

**Primary:**
- Ruby - Primary implementation language for koans, support runtime, Rake tasks, CLI, and internal tests. Core files include `src/neo.rb`, `src/path_to_enlightenment.rb`, `bin/koans`, `Rakefile`, `rakelib/test.rake`, and `tests/koans_cli_test.rb`.
- Supported Ruby versions in CI: Ruby 3.2, 3.3, and 3.4 via `.github/workflows/ci.yml` lines 10-20.

**Secondary:**
- RDoc - Documentation format used by `README.rdoc`, `koans/README.rdoc`, and `DEPLOYING`.
- YAML - GitHub Actions workflow configuration in `.github/workflows/ci.yml`.

## Runtime

**Environment:**
- Ruby runtime selected from the current interpreter for local execution. `bin/koans` runs child Ruby processes via `RbConfig.ruby` in `bin/koans:171-173`, so new CLI code should use the active Ruby rather than hardcoding `ruby` when interpreter consistency matters.
- CI runtime matrix uses Ruby 3.2, 3.3, and 3.4 in `.github/workflows/ci.yml`.
- Koan content includes conditional paths for MRI Ruby, JRuby, Ruby 2.x, Ruby 3.x, and Ruby 4.x via helpers in `src/neo.rb:18-35` and guarded requires in `src/path_to_enlightenment.rb:15-43`.
- JRuby-specific exercises are only loaded when `defined?(JRUBY_VERSION)` matches `in_ruby_version("jruby")` in `src/path_to_enlightenment.rb:38-40`.

**Package Manager:**
- Bundler 4.0.8 - Recorded in `Gemfile.lock:25-26`.
- Lockfile: present at `Gemfile.lock`.
- Package source: RubyGems via `Gemfile:1` and `Gemfile.lock:1-3`.

## Frameworks

**Core:**
- Custom Ruby Koans runner - `src/neo.rb` implements assertions, koan discovery, progress tracking, colored output, and path walking without depending on a web framework.
- Rake 13.4.2 - Build/task runner declared in `Gemfile:4` and locked in `Gemfile.lock:9`. Root tasks live in `Rakefile`; supplemental tasks live in `rakelib/test.rake`, `rakelib/checks.rake`, and `rakelib/run.rake`.
- Bundler - Dependency installation and CI caching through `ruby/setup-ruby@v1` with `bundler-cache: true` in `.github/workflows/ci.yml:17-21`.

**Testing:**
- Minitest 6.0.2 - Internal project test framework declared in `Gemfile:3`, locked in `Gemfile.lock:5-7`, and required by `tests/test_helper.rb:1`.
- Rake::TestTask - Test discovery configured in `rakelib/test.rake:1-7`, using files matching `tests/**/*_test.rb`.
- Custom Neo assertions - Koan exercises use `Neo::Assertions` in `src/neo.rb:147-203`, not Minitest, so code under `src/about_*.rb` and `koans/about_*.rb` should continue using `assert_equal`, `assert`, `assert_raise`, and related Neo helpers.

**Build/Dev:**
- Rake generation pipeline - `Rakefile:99-115` generates learner-facing files in `koans/` from answer-bearing sources in `src/`.
- CLI helper - `bin/koans` provides `walk`, `watch`, `list`, `next`, `hint`, and `reset` commands.
- Watch loop - `bin/koans:49-69` implements polling-based watch mode without a watcher gem. `koans.watchr` exists for legacy Watchr-style usage, but `Gemfile` does not declare `watchr`.
- ZIP packaging - `Rakefile:80-92` builds `download/rubykoans.zip` from generated `koans/` files.

## Key Dependencies

**Critical:**
- `rake` 13.4.2 - Required for default execution (`rake`), generation (`rake gen`), packaging (`rake package`), checks (`rake check`), and internal tests (`rake test`). See `Rakefile:57-75`, `Rakefile:80-115`, and `rakelib/checks.rake:47-48`.
- `minitest` 6.0.2 - Required for tests in `tests/check_test.rb`, `tests/koans_cli_test.rb`, and `tests/neo_output_test.rb` through `tests/test_helper.rb`.

**Infrastructure:**
- `drb` 2.2.3 - Transitive dependency of `minitest` in `Gemfile.lock:4-7`.
- `prism` 1.9.0 - Transitive dependency of `minitest` in `Gemfile.lock:5-8`.
- `fileutils`, `rbconfig`, `English`, `open3`, `tmpdir`, and `stringio` - Ruby standard library usage in `bin/koans` and `tests/`. Keep these as standard-library requires unless a future Ruby version changes availability.
- Optional `win32console` - `src/neo.rb:6-9` and `koans/neo.rb:6-9` attempt to require it and ignore `LoadError`. It is not declared in `Gemfile`, so Windows color support is best-effort.

## Configuration

**Environment:**
- `SIMPLE_KOAN_OUTPUT` - When set to `true`, `src/neo.rb:93-95` switches completion output to a plain text message.
- `NO_COLOR` - Disables ANSI color in `src/neo.rb:125-127`.
- `ANSI_COLOR` - Forces color when it starts with `t` or `y` in `src/neo.rb:127-135`.
- `NEO_DISABLE_END` - Disables the `END` hook in `src/neo.rb:557-562`; used by `bin/koans:221-226` while loading definitions and by `tests/neo_output_test.rb:3`.
- `KOANS_WATCH_INTERVAL` - Controls polling interval for `bin/koans watch` via `bin/koans:175-179`; defaults to `0.5` seconds.
- `KOANS_NO_CLEAR` - Prevents screen clearing in `bin/koans:181-183`.
- `KOANS_PROGRESS_FILE` - Overrides the progress file used by CLI progress commands via `bin/koans:196-198`; tests set it in `tests/koans_cli_test.rb:11-15`.
- No `.env` files detected in the repository root.

**Build:**
- `Gemfile` and `Gemfile.lock` configure Ruby gems.
- `Rakefile` defines generation, walking, packaging, upload, and source-run tasks.
- `rakelib/test.rake` defines `rake test`.
- `rakelib/checks.rake` defines `rake check` consistency checks.
- `.github/workflows/ci.yml` defines GitHub Actions CI.
- `koans.watchr` defines a legacy watcher command that shells out to `ruby bin/koans walk`.

## Platform Requirements

**Development:**
- Ruby plus Bundler. Use `bundle exec rake test check` to match CI from `.github/workflows/ci.yml:23-24`.
- Edit generated exercise files in `koans/` for learning sessions, as documented in `README.rdoc:27-28`.
- Edit source files in `src/` when changing canonical exercise content; regenerate `koans/` with `rake gen` or `rake regen` from `Rakefile:99-115`.
- Use `bin/koans walk` or `rake` for the standard learning loop described in `README.rdoc:14-29`.

**Production:**
- No long-running production service is present.
- Distribution artifact is a ZIP file at `download/rubykoans.zip`, produced by `rake package` through `Rakefile:80-92`.
- Deployment documented in `DEPLOYING:1-12` is repository-based: rebuild `download/rubykoans.zip`, commit `download/`, and push.

---

*Stack analysis: 2026-05-07*
