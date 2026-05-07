# Testing Patterns

**Analysis Date:** 2026-05-07

## Test Framework

**Runner:**
- Minitest 6.0.2
- Config: `rakelib/test.rake`
- Test bootstrap: `tests/test_helper.rb`
- Rake test task loads `tests/**/*_test.rb` through `Rake::TestTask` in `rakelib/test.rake`.

**Assertion Library:**
- Repository tests use Minitest assertions from `minitest/autorun`: `assert`, `refute`, `assert_match`, `refute_match`, `assert_raises` in `tests/koans_cli_test.rb` and `tests/neo_output_test.rb`.
- Koan exercises use the custom `Neo::Assertions` assertion API in `src/neo.rb`: `assert`, `assert_equal`, `assert_not_equal`, `assert_nil`, `assert_not_nil`, `assert_match`, `assert_raise`, `assert_nothing_raised`.

**Run Commands:**
```bash
bundle exec rake test              # Run all Minitest tests in tests/**/*_test.rb
bundle exec rake check             # Run koan consistency checks from rakelib/checks.rake
bundle exec rake test check        # Run the same verification used by CI
rake walk_the_path                 # Generate koans and walk until the first unanswered koan
rake run_all                       # Run completed source koans through src/path_to_enlightenment.rb
```

## Test File Organization

**Location:**
- Repository regression tests live in `tests/` and are loaded by `rakelib/test.rake`.
- Teaching tests/koans live as source files in `src/about_*.rb`; generated learner copies live in `koans/about_*.rb`.
- Runtime support for custom koan tests lives in `src/neo.rb`; generated runtime copy exists at `koans/neo.rb`.
- Rake-level consistency checks live in `rakelib/checks.rake` and are covered by `tests/check_test.rb`.

**Naming:**
- Minitest files use `*_test.rb`: `tests/check_test.rb`, `tests/koans_cli_test.rb`, `tests/neo_output_test.rb`.
- Minitest classes end with `Test`: `CheckTest`, `KoansCliTest`, `NeoOutputTest`.
- Minitest methods start with `test_`: `test_help_shows_commands`, `test_assert_nothing_raised_reports_the_actual_exception`.
- Koan files use `about_<topic>.rb`; classes use `About<Topic>` and test methods start with `test_`: `src/about_exceptions.rb`, `src/about_proxy_object_project.rb`.

**Structure:**
```
tests/
├── test_helper.rb          # Minitest, Rake, StringIO bootstrap
├── check_test.rb           # Rake consistency check tests
├── koans_cli_test.rb       # bin/koans subprocess CLI tests
└── neo_output_test.rb      # Neo runtime output/assertion tests

src/
├── neo.rb                  # Custom koan runtime and assertion framework
├── path_to_enlightenment.rb # Ordered koan manifest
└── about_*.rb              # Teaching tests executed by Neo::ThePath
```

## Test Structure

**Suite Organization:**
```ruby
require_relative "test_helper"

class KoansCliTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  CLI = File.join(ROOT, "bin", "koans")

  def run_cli(*args, progress_file: nil)
    env = {}
    env["KOANS_PROGRESS_FILE"] = progress_file if progress_file

    Open3.capture3(env, RbConfig.ruby, CLI, *args, chdir: ROOT)
  end

  def test_help_shows_commands
    stdout, stderr, status = run_cli("help")

    assert_success(status, stderr)
    assert_match(/Usage: bin\/koans <command>/, stdout)
  end
end
```

**Patterns:**
- Put shared test bootstrap in `tests/test_helper.rb`; every Minitest file requires it first.
- Use helper methods inside each test class for repeated setup and assertions: `run_cli`, `with_progress`, `assert_success` in `tests/koans_cli_test.rb`; `capture_stdout` in `tests/neo_output_test.rb`.
- Keep tests action-oriented: command execution or object setup first, then assertions. `tests/koans_cli_test.rb` consistently captures `stdout, stderr, status` before assertions.
- Use regular expressions for CLI text assertions so tests remain stable across line numbers or formatting changes: `assert_match(%r{koans/about_asserts\.rb:\d+}, stdout)` in `tests/koans_cli_test.rb`.
- For koan source tests, use custom `Neo::Koan` subclasses and `assert_equal expected, actual` style: `src/about_triangle_project.rb`, `src/about_dice_project.rb`.

## Mocking

**Framework:** none detected

**Patterns:**
```ruby
def with_progress(contents=nil)
  Dir.mktmpdir do |dir|
    progress_file = File.join(dir, ".path_progress")
    File.write(progress_file, contents) if contents
    yield progress_file
  end
end
```

```ruby
def capture_stdout
  original_stdout = $stdout
  $stdout = StringIO.new
  yield
  $stdout.string
ensure
  $stdout = original_stdout
end
```

**What to Mock:**
- Prefer temporary files/directories over mocks for filesystem state: `Dir.mktmpdir` and `KOANS_PROGRESS_FILE` in `tests/koans_cli_test.rb`.
- Capture global stdout with `StringIO` when verifying printed output: `tests/check_test.rb`, `tests/neo_output_test.rb`.
- Use subprocess execution for CLI behavior rather than stubbing internals: `Open3.capture3` in `tests/koans_cli_test.rb`.
- Set environment variables to control runtime side effects: `ENV['NEO_DISABLE_END'] = 'true'` in `tests/neo_output_test.rb`; `KOANS_PROGRESS_FILE` in `tests/koans_cli_test.rb`.

**What NOT to Mock:**
- Do not mock `bin/koans` command dispatch when testing CLI behavior; execute it with `RbConfig.ruby` and assert status/output as in `tests/koans_cli_test.rb`.
- Do not mock Rake tasks for consistency checks; invoke `Rake::Task['check:asserts']` and `Rake::Task['check:abouts']` as in `tests/check_test.rb`.
- Do not mock koan assertion classes when testing output formatting; construct real `Neo::Assertions::FailedAssertionError`, `NameError`, and `Neo::Sensei` objects as in `tests/neo_output_test.rb`.

## Fixtures and Factories

**Test Data:**
```ruby
failure = Neo::Assertions::FailedAssertionError.new("Expected 2 to equal 999999")
failure.set_backtrace(["./about_asserts.rb:52:in `test_fill_in_values'", "./neo.rb:1"])

sensei = Neo::Sensei.new
sensei.instance_variable_set(:@failure, failure)
```

```ruby
with_progress("0") do |progress_file|
  stdout, stderr, status = run_cli("next", progress_file: progress_file)

  assert_success(status, stderr)
  assert_match(/AboutAsserts#test_assert_truth/, stdout)
end
```

**Location:**
- No dedicated fixtures directory exists.
- Inline fixtures are used in test files: fake backtraces in `tests/neo_output_test.rb`, progress-file contents in `tests/koans_cli_test.rb`.
- Static teaching/support files live in `koans/example_file.txt` and `koans/GREED_RULES.txt`; they support koan content rather than Minitest fixtures.

## Coverage

**Requirements:** None enforced

**View Coverage:**
```bash
# Not configured. No SimpleCov or coverage task is present.
bundle exec rake test
```

## Test Types

**Unit Tests:**
- Use Minitest for focused runtime behavior in `tests/neo_output_test.rb`.
- Use direct object construction for `Neo::Sensei`, `Neo::Koan`, and assertion errors in `tests/neo_output_test.rb`.
- Use `assert_raises` for expected runtime errors, e.g. `Neo::Koan#assert_nothing_raised` behavior in `tests/neo_output_test.rb`.

**Integration Tests:**
- CLI integration tests run `bin/koans` as a subprocess through `Open3.capture3` in `tests/koans_cli_test.rb`.
- Rake integration tests load the project Rakefile in `tests/test_helper.rb` and invoke named tasks in `tests/check_test.rb`.
- The custom koan path integration runs through `rake walk_the_path`, `rake run_all`, and `src/path_to_enlightenment.rb`.

**E2E Tests:**
- No browser or external E2E framework is used.
- CLI subprocess tests in `tests/koans_cli_test.rb` are the closest end-to-end coverage because they exercise command parsing, environment configuration, file progress state, and output.

## Common Patterns

**Async Testing:**
```ruby
stdout, stderr, status = Open3.capture3(env, RbConfig.ruby, CLI, *args, chdir: ROOT)
assert status.success?, stderr
assert_match(/The next stone on the path:/, stdout)
```

The codebase does not use async primitives. Subprocess tests should capture stdout, stderr, and status in one call as in `tests/koans_cli_test.rb`.

**Error Testing:**
```ruby
stdout, stderr, status = run_cli("reset")

refute status.success?, stdout
assert_match(/Usage: bin\/koans reset/, stderr)
```

```ruby
error = assert_raises(Neo::Assertions::FailedAssertionError) do
  koan.assert_nothing_raised { raise ArgumentError, "bad path" }
end

assert_match(/ArgumentError/, error.message)
assert_match(/bad path/, error.message)
```

Use `refute status.success?` for CLI failures, `assert_raises` for Ruby exception behavior, and `assert_raise` for custom Neo koan assertions inside `src/about_*.rb` files.

---

*Testing analysis: 2026-05-07*
