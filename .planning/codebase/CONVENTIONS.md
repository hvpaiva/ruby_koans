# Coding Conventions

**Analysis Date:** 2026-05-07

## Naming Patterns

**Files:**
- Use snake_case Ruby file names for source and koan files: `src/about_asserts.rb`, `src/about_triangle_project.rb`, `src/path_to_enlightenment.rb`.
- Use `about_<topic>.rb` for instructional koan files that define one or more `Neo::Koan` subclasses: `src/about_proxy_object_project.rb`, `src/about_exceptions.rb`.
- Keep generated learner-facing copies in `koans/` with the same basename as `src/`: `src/about_strings.rb` generates `koans/about_strings.rb`.
- Use `_test.rb` suffix for Minitest tests under `tests/`: `tests/check_test.rb`, `tests/koans_cli_test.rb`, `tests/neo_output_test.rb`.
- CLI executable is extensionless and lives in `bin/`: `bin/koans`.

**Functions:**
- Use snake_case method names throughout Ruby code: `RubyKoansCLI.current_step` in `bin/koans`, `Neo::Sensei#guide_through_error` in `src/neo.rb`.
- Koan assertions must be in methods named `test_<behavior>` so `Neo::Koan.method_added` registers them through `Neo::Koan.test_pattern` in `src/neo.rb`.
- Helper methods should describe behavior rather than implementation details: `with_captured_stdout` in `tests/check_test.rb`, `capture_stdout` in `tests/neo_output_test.rb`, `normalize_target_file` in `bin/koans`.
- Predicate methods use `?`: `Neo.simple_output`, `Neo::Color.use_colors?`, `Neo::Koan#passed?`, `Television#on?` in `src/neo.rb` and `src/about_proxy_object_project.rb`.

**Variables:**
- Use snake_case locals: `progress_file`, `last_signature`, `expected_value`, `actual_value` in `bin/koans` and `src/about_asserts.rb`.
- Use uppercase constants for configuration paths and class-level values: `RubyKoansCLI::ROOT`, `RubyKoansCLI::SRC_DIR`, `RubyKoansCLI::KOANS_DIR` in `bin/koans`; `SRC_DIR`, `PROB_DIR`, `ZIP_FILE` in `Rakefile`.
- Use instance variables for object state: `@failure`, `@pass_count`, `@observations` in `src/neo.rb`; `@messages` in `src/about_proxy_object_project.rb`.
- Prefer descriptive domain names in koans: `dice`, `first_time`, `second_time` in `src/about_dice_project.rb`; `tv`, `proxy`, `method_name` in `src/about_proxy_object_project.rb` and `bin/koans`.

**Types:**
- Use CamelCase for classes and modules: `RubyKoansCLI` in `bin/koans`, `Neo::Sensei` and `Neo::Koan` in `src/neo.rb`, `AboutAsserts` in `src/about_asserts.rb`.
- Koan classes use `About<Topic>` naming and inherit from `Neo::Koan`: `AboutExceptions < Neo::Koan` in `src/about_exceptions.rb`, `AboutTriangleProject < Neo::Koan` in `src/about_triangle_project.rb`.
- Custom error classes end with `Error`: `FillMeInError` in `src/neo.rb`, `MySpecialError` in `src/about_exceptions.rb`.

## Code Style

**Formatting:**
- No formatter config is detected: no `.rubocop.yml`, `.standard.yml`, or SimpleCov config files are present.
- Use two-space indentation in Ruby files: `bin/koans`, `tests/koans_cli_test.rb`, and `src/about_dice_project.rb` follow this style.
- Use blank lines between logical setup, action, and assertion blocks in tests: `tests/koans_cli_test.rb` separates command execution from assertions.
- Keep method bodies compact in koan files. Most instructional tests in `src/about_asserts.rb`, `src/about_triangle_project.rb`, and `src/about_exceptions.rb` are short and focused.
- String literal style is mixed by file generation era. Newer CLI and tests use double quotes (`bin/koans`, `tests/test_helper.rb`); legacy koan runtime uses single quotes in many places (`src/neo.rb`, `Rakefile`). Match the surrounding file.
- Frozen string literal is present only in the CLI executable: keep `# frozen_string_literal: true` at the top of `bin/koans`; do not add it broadly to legacy koan files without checking mutation behavior.

**Linting:**
- No lint tool is configured in `Gemfile`, `Gemfile.lock`, or repository config files.
- CI runs tests and consistency checks only: `.github/workflows/ci.yml` executes `bundle exec rake test check`.
- Rake consistency checks live in `rakelib/checks.rake`; use them for koan-specific hygiene rather than style enforcement.

## Import Organization

**Order:**
1. Test files require project test setup first with `require_relative "test_helper"`: `tests/check_test.rb`, `tests/koans_cli_test.rb`, `tests/neo_output_test.rb`.
2. Test files then require standard library dependencies: `open3`, `rbconfig`, `tmpdir` in `tests/koans_cli_test.rb`.
3. Source koan files require the koan runtime first: `require File.expand_path(File.dirname(__FILE__) + '/neo')` in `src/about_asserts.rb` and `src/about_exceptions.rb`.
4. Project koans require local implementation files after loading `neo`: `require './triangle'` in `src/about_triangle_project.rb`.
5. CLI code requires standard libraries at the top: `fileutils`, `rbconfig`, and `English` in `bin/koans`.

**Path Aliases:**
- No Bundler, Zeitwerk, Rails, or Ruby load-path aliasing is configured.
- `src/path_to_enlightenment.rb` mutates `$LOAD_PATH` with `File.dirname(__FILE__)`, then loads koans by basename (`require 'about_asserts'`).
- `bin/koans` loads koan definitions by unshifting `SRC_DIR` into `$LOAD_PATH` and loading `src/path_to_enlightenment.rb`.

## Error Handling

**Patterns:**
- Use `return 1`/`return 0` status codes in CLI command methods instead of raising for expected user errors: `RubyKoansCLI#reset`, `#walk`, `#hint` in `bin/koans`.
- Print user-facing CLI errors to stderr with `warn`: unknown commands and reset usage errors in `bin/koans`.
- Rescue narrow, expected conversion errors where user input is parsed: `watch_interval` rescues `ArgumentError` and returns `0.5` in `bin/koans`.
- Validate file input before writing or copying: `normalize_target_file` raises `ArgumentError` for unsafe file names and `reset` checks `File.file?(source)` in `bin/koans`.
- Koan runtime assertions raise `Neo::Assertions::FailedAssertionError`: assertion helpers in `src/neo.rb` call `flunk` on failed conditions.
- Koan execution captures failures in `Neo::Koan#meditate` and stores them on the step instead of letting normal koan failures terminate the process immediately: `src/neo.rb`.
- Use `ensure` when global state must be restored: stdout capture helpers in `tests/check_test.rb` and `tests/neo_output_test.rb` reset `$stdout` in `ensure`.

## Logging

**Framework:** console

**Patterns:**
- Use `puts` for normal CLI/runtime output: path listing in `bin/koans`, Sensei guidance in `src/neo.rb`, check output in `rakelib/checks.rake`.
- Use `warn` for CLI errors and usage failures: `bin/koans` unknown command and reset validation paths.
- Use Rake `sh` for command execution in build/package tasks: `Rakefile` tasks `:run`, `:package`, and `:upload`.
- Do not introduce a logging framework unless the project adds a broader runtime architecture; current code is a command-line teaching tool.

## Comments

**When to Comment:**
- Use comments to explain koan teaching intent immediately above the test they describe: `src/about_asserts.rb`, `src/about_exceptions.rb`.
- Preserve `#--` and `#++` markers in `src/` koan source files; `Rakefile` and `bin/koans` use them to strip solution sections when generating `koans/`.
- Use comments to mark learner implementation areas in project koans: `src/about_dice_project.rb`, `src/about_proxy_object_project.rb`.
- Keep operational comments short and local to the relevant code: solution-stripping comments in `Rakefile`, proxy support boundary comments in `src/about_proxy_object_project.rb`.

**JSDoc/TSDoc:**
- Not applicable. The project is Ruby and does not use formal RDoc/YARD annotations in source files.
- README files use RDoc format: `README.rdoc`, `koans/README.rdoc`.

## Function Design

**Size:** Keep most methods short and single-purpose. CLI methods in `bin/koans` usually perform one command or one helper operation; koan test methods in `src/about_*` files usually assert one concept.

**Parameters:** Use simple positional parameters for internal helpers (`run(command, directory)` in `bin/koans`, `Koans.make_koan_file(infile, outfile)` in `Rakefile`). Use keyword parameters for optional test helper context where readability matters (`run_cli(*args, progress_file: nil)` in `tests/koans_cli_test.rb`).

**Return Values:**
- CLI command methods return process exit codes (`0`/`1`) in `bin/koans`.
- Predicate methods return booleans and end in `?`: `current_step` returns a step hash or nil, while `use_colors?`, `passed?`, and `assert_failed?` return truthy/falsey values in `src/neo.rb`.
- Assertion helpers return `true` on pass and raise on failure: `assert`, `assert_equal`, `assert_raise` in `src/neo.rb`.

## Module Design

**Exports:**
- Use modules as namespaces for cohesive groups: `RubyKoansCLI` in `bin/koans`, `Neo` in `src/neo.rb`, `Koans` in `Rakefile`.
- Use `class << self` for module-level command/helper methods: `RubyKoansCLI` in `bin/koans`, `Neo.simple_output` in `src/neo.rb`.
- Use `module_function` when module methods are intended to be callable directly: `Neo::Color` in `src/neo.rb`.
- Keep test-only helpers private by convention inside test classes; helpers like `with_progress` and `assert_success` live in `KoansCliTest` in `tests/koans_cli_test.rb`.

**Barrel Files:**
- No barrel/index files are used.
- `src/path_to_enlightenment.rb` is the ordered runtime manifest for koan files; add new instructional koans there when they should become part of the path.
- `tests/test_helper.rb` is the shared test bootstrap; put test-wide setup there only when all Minitest tests need it.

---

*Convention analysis: 2026-05-07*
