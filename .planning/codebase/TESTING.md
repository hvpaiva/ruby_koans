# Testing Patterns

**Analysis Date:** 2026-05-07

This codebase has **two test layers** that should not be confused:

1. **The koans themselves are the curriculum.** Files in `src/about_*.rb`
   (and the generated `koans/about_*.rb`) are written as failing tests
   that learners convert into passing tests. They run on a custom in-tree
   runner — `Neo` — defined in `src/neo.rb`. They do **not** use minitest
   or rspec.
2. **The `tests/` directory validates the runner and the CLI itself.**
   It uses minitest and exists to make sure that `bin/koans`, the
   `Rakefile`, and `Neo::Sensei` keep behaving correctly across Ruby
   versions.

The `Gemfile` lists only `minitest` and `rake`. There is no `rspec`,
`shoulda`, `mocha`, or `factory_bot`.

## Test Frameworks

**Curriculum runner — `Neo` (custom):**
- Defined in `src/neo.rb`.
- Entry point: `Neo::ThePath#walk`, kicked off from the `END {}` hook at
  `src/neo.rb:557-562` when `path_to_enlightenment.rb` is loaded (unless
  `NEO_DISABLE_END=true`).
- Test pattern: every instance method named `/^test_/` on a subclass of
  `Neo::Koan` becomes a step (`src/neo.rb:485-487`, `src/neo.rb:524-526`).
- Run command (canonical): `rake` (alias for `rake walk_the_path`,
  `Rakefile:57-67`). The first run regenerates `koans/` from `src/` then
  executes `koans/path_to_enlightenment.rb`.
- Modern alternative: `bin/koans walk` (`bin/koans:43-47`).

**Self-test runner — minitest:**
- Version: `minitest 6.0.2` (`Gemfile.lock:5`).
- Config: `rakelib/test.rake`:
  ```ruby
  require 'rake/testtask'

  Rake::TestTask.new do |t|
    t.libs << "tests"
    t.test_files = FileList["tests/**/*_test.rb"]
    t.verbose = true
  end
  ```
- Run command: `bundle exec rake test`.
- CI command: `bundle exec rake test check`
  (`.github/workflows/ci.yml:24`).
- Ruby matrix: `3.2`, `3.3`, `3.4` (`.github/workflows/ci.yml:11`).

## Run Commands

```bash
# Walk the koans (curriculum, custom Neo runner)
rake                          # default task → walk_the_path
rake walk                     # alias for walk_the_path
bin/koans walk                # equivalent, modern CLI
bin/koans watch               # auto-rerun on koan file changes
bin/koans list                # show progress-aware path overview
bin/koans next                # show next remembered step
bin/koans hint                # show hint comment for next step

# Self-tests (minitest, exercises bin/koans + Neo + Rakefile)
bundle exec rake test         # all tests in tests/**/*_test.rb
bundle exec rake check        # consistency checks on src/
bundle exec rake test check   # exact CI invocation

# Curriculum integrity checks
rake check                    # runs check:abouts and check:asserts
rake check:abouts             # every src/about_*.rb is required from path_to_enlightenment.rb
rake check:asserts            # every assert has a __ / _n_ placeholder
```

## Test File Organization

**Curriculum (the koans):**
- Authored in `src/about_*.rb`, one topic per file (37 files as of this
  analysis).
- Generated for the learner into `koans/about_*.rb` by
  `Koans.make_koan_file` (`Rakefile:34-54`) which strips
  `__(answer)` arguments, `# __` markers, and `#--`/`#++` solution
  blocks. `koans/` is `.gitignore`d (`*.gitignore:10` —
  `koans/*`).
- Order is canonical and explicit, set by
  `src/path_to_enlightenment.rb` (`src/path_to_enlightenment.rb:1-45`).
  This is the only place that decides what runs and in what sequence.

**Self-tests (the runner's tests):**
- Live in `tests/`:
  - `tests/test_helper.rb` — minimal, requires
    `minitest/autorun`, `rake`, and `stringio`, then loads the project
    `Rakefile` so tests can invoke real Rake tasks.
  - `tests/check_test.rb` — exercises `rake check:asserts` and
    `rake check:abouts` end-to-end by invoking the tasks and
    asserting the captured stdout matches `/OK/`.
  - `tests/koans_cli_test.rb` — black-box integration tests for
    `bin/koans` via `Open3.capture3`.
  - `tests/neo_output_test.rb` — white-box tests of `Neo::Sensei` and
    `Neo::Koan` output guarantees (e.g. error messages must not leak
    expected values).
- File naming: `<subject>_test.rb` (matches the Rake test task's
  `FileList["tests/**/*_test.rb"]`).
- Class naming: `class <Subject>Test < Minitest::Test`.

## How `tests/` Relates to `koans/`

The two directories serve **opposite** purposes and must not be conflated:

| Concern | `koans/` (and `src/`) | `tests/` |
|---------|------------------------|----------|
| Runner | Custom `Neo` runner (`src/neo.rb`) | Minitest |
| Audience | The student | Maintainers / CI |
| Pass/fail meaning | Failing test = lesson not yet learned | Failing test = bug in tooling |
| Generated? | `koans/` regenerated from `src/` | Hand-written |
| Tracked in git? | `src/` yes, `koans/` no | yes |
| Run on CI? | No (the failing koans would block CI) | Yes (`rake test check`) |

`tests/` files **load the curriculum infrastructure** to verify it. For
example, `tests/neo_output_test.rb:3-4`:
```ruby
ENV['NEO_DISABLE_END'] = 'true'
require_relative "../src/neo"
```
The `NEO_DISABLE_END` env var is honored by `src/neo.rb:557` to suppress
the auto-walk in the `END {}` block, so requiring `neo.rb` from a
minitest file does not start the koan walk.

`tests/koans_cli_test.rb` similarly drives `bin/koans` as a subprocess
with controlled `KOANS_PROGRESS_FILE` env vars (see "Common Patterns"
below).

## The Koan-as-Failing-Test Idiom

Every curriculum file is structured as a class of `test_*` methods that
**start out failing** and become passing when the student fills in the
right values.

```ruby
require File.expand_path(File.dirname(__FILE__) + '/neo')

class AboutAsserts < Neo::Koan

  # We shall contemplate truth by testing reality, via asserts.
  def test_assert_truth
    assert false                # This should be true
  end

  # Sometimes we will ask you to fill in the values
  def test_fill_in_values
    assert_equal __, 1 + 1
  end
end
```
(`koans/about_asserts.rb:6-39`)

To make these pass, the student edits the koan file directly:
- `assert false` → `assert true`.
- `assert_equal __, 1 + 1` → `assert_equal 2, 1 + 1`.

The `__` / `_n_` / `___` / `____` placeholders are defined as global
helpers in `src/neo.rb:39-76`. In the source file (`src/`) they take an
argument that holds the answer; `rake gen` strips that argument out when
producing `koans/`. See `CONVENTIONS.md` for the full vocabulary.

**Custom assertions available inside any `Neo::Koan` subclass**
(`src/neo.rb:147-203`):
| Assertion | Purpose |
|-----------|---------|
| `assert(cond, msg=nil)` | Truthiness |
| `assert_equal(expected, actual, msg=nil)` | Value equality |
| `assert_not_equal(expected, actual, msg=nil)` | Inequality |
| `assert_nil(actual, msg=nil)` / `assert_not_nil` | Nil checks |
| `assert_match(pattern, actual, msg=nil)` | Regex match |
| `assert_raise(exception_class) { … }` | Asserts a specific raise; returns the exception so the koan can inspect it |
| `assert_nothing_raised { … }` | Inverse of `assert_raise` |
| `flunk(msg)` | Force a failure |

These names overlap with minitest's classic API but are unrelated
implementations — `Neo::Assertions::FailedAssertionError`
(`src/neo.rb:148`) is the only failure type.

## Test Structure (curriculum)

**Suite organisation:**
```ruby
require File.expand_path(File.dirname(__FILE__) + '/neo')

class AboutTopic < Neo::Koan
  # Optional helper classes scoped to the lesson
  class Helper
    ...
  end

  # Optional setup / teardown (no-ops by default)
  # def setup; end
  # def teardown; end

  # One lesson per test_ method
  def test_a_thing
    assert_equal __(answer), code_under_examination
  end
end
```
(`src/about_message_passing.rb`, `src/about_classes.rb` etc.)

**Lifecycle (`src/neo.rb:457-477`):**
- `setup` runs before each `test_*` method, `teardown` after — both are
  empty defaults that subclasses may override.
- The runner wraps the test body in `begin/rescue/ensure` so even an
  exception in `teardown` is recorded as a failure on the same step.
- The first failing step short-circuits the entire walk via
  `throw :neo_exit` (`src/neo.rb:252` and `src/neo.rb:543-553`). The
  student fixes one koan, reruns, and the path resumes from the next
  step.

**Project-style koans** (`src/about_triangle_project.rb`,
`src/about_dice_project.rb`, `src/about_scoring_project.rb`,
`src/about_proxy_object_project.rb`) follow the same `Neo::Koan` shape
but use **literal expected values** instead of `__()` placeholders,
because the puzzle is to write the production code (e.g.
`src/triangle.rb`) until the assertions pass:
```ruby
class AboutTriangleProject < Neo::Koan
  def test_equilateral_triangles_have_equal_sides
    assert_equal :equilateral, triangle(2, 2, 2)
    assert_equal :equilateral, triangle(10, 10, 10)
  end
end
```
(`src/about_triangle_project.rb:7-10`). `rake check:asserts` skips files
matching `project` so these are not flagged for missing placeholders
(`rakelib/checks.rake:25`).

## Test Structure (self-tests, minitest)

**Header:**
```ruby
require_relative "test_helper"

class CheckTest < Minitest::Test
  ...
end
```
(`tests/check_test.rb:1-3`).

**`test_helper.rb` (minimal, `tests/test_helper.rb:1-5`):**
```ruby
require "minitest/autorun"
require "rake"
require "stringio"

Rake.application.load_rakefile
```
Loading the Rakefile here lets tests invoke Rake tasks
(e.g. `Rake::Task['check:asserts'].invoke` in
`tests/check_test.rb:15`).

**Conventions for self-tests:**
- One `class FooTest < Minitest::Test` per file.
- Test method names are `test_<assertion-shaped>`:
  `test_help_shows_commands`, `test_assertion_failure_does_not_print_the_answer`.
- Use `assert_match`, `refute_match`, `assert`, `refute`,
  `assert_raises`. (`tests/neo_output_test.rb:25-28`,
  `tests/koans_cli_test.rb:34-37`).
- Capture stdout with a small helper rather than a library:
  ```ruby
  def with_captured_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
  ```
  (`tests/check_test.rb:4-11`, `tests/neo_output_test.rb:7-14`).

## Mocking

**No mocking framework** is in use (no `mocha`, `rspec-mocks`, or
`minitest/mock` references).

Strategies used instead:
- **Subprocess isolation** — `tests/koans_cli_test.rb:11-16` runs
  `bin/koans` via `Open3.capture3(env, RbConfig.ruby, CLI, *args, chdir: ROOT)`,
  so the CLI is exercised exactly as a user would invoke it. The minitest
  process never imports CLI internals.
- **Tmp-dir progress files** — `tests/koans_cli_test.rb:18-24` uses
  `Dir.mktmpdir` and points `KOANS_PROGRESS_FILE` at a fresh path so
  tests do not collide with a real `.path_progress`:
  ```ruby
  def with_progress(contents=nil)
    Dir.mktmpdir do |dir|
      progress_file = File.join(dir, ".path_progress")
      File.write(progress_file, contents) if contents
      yield progress_file
    end
  end
  ```
- **Direct construction with instance variable injection** — when
  testing `Neo::Sensei` output, the test builds a real `Sensei` and
  assigns the failure manually rather than running a koan:
  ```ruby
  failure = Neo::Assertions::FailedAssertionError.new("Expected 2 to equal 999999")
  failure.set_backtrace(["./about_asserts.rb:52:in `test_fill_in_values'", "./neo.rb:1"])
  sensei = Neo::Sensei.new
  sensei.instance_variable_set(:@failure, failure)
  output = capture_stdout { sensei.guide_through_error }
  ```
  (`tests/neo_output_test.rb:17-23`).

**What to mock:** nothing in the curriculum. Mocking would defeat the
lesson — koans deliberately exercise real Ruby semantics.

**What NOT to mock in self-tests:** the file system, the Rake task graph,
or the CLI process. The existing tests verify those exact things end to
end; preserve that.

## Fixtures and Factories

There is no fixtures/factories library and no shared `support/`
directory. Fixture data lives next to the koan that needs it:
- `src/example_file.txt` and `koans/example_file.txt` — used by
  `src/about_sandwich_code.rb` (`open("example_file.txt")` at
  `src/about_sandwich_code.rb:6, 23, 58, 100`).
- `src/triangle.rb` and `koans/triangle.rb` — production code under test
  by `about_triangle_project.rb` and `about_triangle_project_2.rb`.
- `src/GREED_RULES.txt` — referenced by the `about_extra_credit.rb`
  prompt.

For self-tests, fixtures are created on the fly in `Dir.mktmpdir` blocks
(`tests/koans_cli_test.rb:18-24`).

## Coverage

**No coverage tool is configured** (no `simplecov`, `.simplecov`, or
coverage gem). CI does not produce a coverage report.

**Curriculum coverage is enforced structurally** by `rake check`
(`rakelib/checks.rake`):
- `check:abouts` — confirms every `src/about_*.rb` appears in
  `src/path_to_enlightenment.rb` so no koan is silently dropped from the
  walk.
- `check:asserts` — confirms every `assert*` in a non-intro,
  non-`project` file has a `__` or `_n_` placeholder, so no koan ships
  with the answer baked in.

When adding new koans, both checks must pass (`bundle exec rake check`).

## Test Types

**Custom-runner tests (the koans):**
- Style: pedagogical, intentionally failing.
- Scope: a single Ruby concept per `test_*` method.
- Boundary: each `About<Topic>` class. The path order in
  `src/path_to_enlightenment.rb` defines pedagogical dependency, not
  runtime dependency.

**Minitest unit/integration tests (`tests/`):**
- `tests/check_test.rb` — Rake task integration (invokes
  `check:abouts` and `check:asserts`, asserts on captured stdout).
- `tests/neo_output_test.rb` — white-box on `Neo::Sensei` and
  `Neo::Koan`; checks that the expected/actual answer is **not** leaked
  on assertion failures (`tests/neo_output_test.rb:16-29`), and that
  runtime errors do surface their context
  (`tests/neo_output_test.rb:42-54`).
- `tests/koans_cli_test.rb` — black-box on `bin/koans`; spawns the CLI
  with `Open3` and asserts on stdout/stderr/exit status for each
  command (`help`, `list`, `next`, `hint`, `reset`).

**No e2e/browser tests.** This is a CLI-only repo.

## Common Patterns

**Subprocess invocation of the CLI:**
```ruby
def run_cli(*args, progress_file: nil)
  env = {}
  env["KOANS_PROGRESS_FILE"] = progress_file if progress_file
  Open3.capture3(env, RbConfig.ruby, CLI, *args, chdir: ROOT)
end

def assert_success(status, stderr)
  assert status.success?, stderr
end
```
(`tests/koans_cli_test.rb:11-28`). Always pass `RbConfig.ruby` so the
subprocess uses the same Ruby as the test.

**Capture stdout from in-process code:**
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
(`tests/neo_output_test.rb:7-14`). Use this when calling `Neo::Sensei`
methods directly.

**Assert that an answer is NOT leaked on failure:**
```ruby
output = capture_stdout { sensei.guide_through_error }

refute_match(/Expected 2 to equal 999999/, output)
refute_match(/The answers you seek/, output)
assert_match(/The answer is hidden, so the discovery remains yours\./, output)
```
(`tests/neo_output_test.rb:23-28`). This is a critical guarantee of the
runner — any change to `Neo::Sensei#guide_through_error`
(`src/neo.rb:362-375`) must keep this test passing.

**Drive Rake tasks from inside a test:**
```ruby
output = with_captured_stdout do
  Rake::Task['check:asserts'].invoke
end
assert_match(/OK/, output)
```
(`tests/check_test.rb:13-18`).

**Async/timing testing:** None — the runner is synchronous and there are
no time-dependent tests.

**Error testing in koans (uses `Neo::Assertions`, not minitest):**
```ruby
exception = assert_raise(___(NoMethodError)) do
  typical.foobar
end
assert_match(/foobar/, exception.message) # __
```
(`src/about_message_passing.rb:80-85`).

**Error testing in self-tests (uses minitest):**
```ruby
error = assert_raises(Neo::Assertions::FailedAssertionError) do
  koan.assert_nothing_raised { raise ArgumentError, "bad path" }
end
assert_match(/ArgumentError/, error.message)
```
(`tests/neo_output_test.rb:33-38`).

## Runner Internals (Reference)

For maintainers touching the runner, the key collaborators are:

| Class | File | Responsibility |
|-------|------|----------------|
| `Neo::Koan` | `src/neo.rb:436-532` | Base class for all `About*` koans. Tracks `subclasses`, `testmethods`, `total_tests`. Provides `meditate` lifecycle. |
| `Neo::Assertions` | `src/neo.rb:147-203` | Mixed into `Neo::Koan`. Defines all `assert_*` methods. |
| `Neo::Sensei` | `src/neo.rb:205-434` | Observes each step, prints colored progress, persists pass count to `.path_progress`, prints zen statements and the final ASCII screen. |
| `Neo::ThePath` | `src/neo.rb:534-554` | Walks every subclass × testmethod in registration order, yields each step to the Sensei, catches `:neo_exit` on first failure. |
| `Neo::Color` | `src/neo.rb:98-145` | TTY/`NO_COLOR`-aware ANSI helpers. |
| `Neo.simple_output` | `src/neo.rb:92-96` | Toggles the ASCII end-screen vs the plain "Mountains are again merely mountains" line. Driven by `SIMPLE_KOAN_OUTPUT=true`. |

**Environment variables that affect tests:**
- `NEO_DISABLE_END=true` — suppresses the `END {}` auto-walk so
  `src/neo.rb` can be required from minitest without side effects
  (`src/neo.rb:557`, `tests/neo_output_test.rb:3`).
- `KOANS_PROGRESS_FILE` — overrides `.path_progress` location
  (`bin/koans:197`, used in `tests/koans_cli_test.rb:13`).
- `KOANS_WATCH_INTERVAL` — float seconds for `bin/koans watch` poll
  (`bin/koans:175-179`).
- `KOANS_NO_CLEAR=1` — skip the `clear` between watch iterations
  (`bin/koans:181-183`).
- `NO_COLOR`, `ANSI_COLOR` — color toggles in `Neo::Color.use_colors?`
  (`src/neo.rb:125-136`).
- `SIMPLE_KOAN_OUTPUT=true` — replace the ASCII end-screen with a single
  line (`src/neo.rb:93-95`, `src/neo.rb:295-305`).

## Continuous Integration

`.github/workflows/ci.yml` runs on push and pull request
(`.github/workflows/ci.yml:1-3`):
- Triggers: `[push, pull_request]`.
- Matrix: `ruby-version: ["3.2", "3.3", "3.4"]`, `fail-fast: false`.
- Setup: `ruby/setup-ruby@v1` with `bundler-cache: true`.
- Single test step: `bundle exec rake test check`.

**What CI does and does not run:**
- ✅ Runs `tests/**/*_test.rb` via the minitest task in
  `rakelib/test.rake`.
- ✅ Runs `rake check` (curriculum integrity).
- ❌ Does **not** run the koans themselves (`rake walk`) — they are
  designed to fail until the learner fills them in, so executing them in
  CI would always fail. The koan suite is deliberately not part of the
  CI signal.

## Adding New Tests

**Adding a new koan (curriculum):**
1. Create `src/about_<topic>.rb` following the conventions in
   `CONVENTIONS.md` (one `About<Topic> < Neo::Koan` class, `test_*`
   methods, placeholders for answers, hint comment above each method).
2. Add `require 'about_<topic>'` to `src/path_to_enlightenment.rb` at the
   pedagogically correct point.
3. Run `bundle exec rake check` — both `check:abouts` and
   `check:asserts` must report `OK`.
4. Run `rake gen` then walk the path manually to confirm the koan is
   solvable.
5. Do **not** add tests to `tests/` for the new koan content. The
   self-tests cover the runner, not lesson content.

**Adding a new self-test:**
1. Create `tests/<subject>_test.rb`.
2. Start with `require_relative "test_helper"`.
3. Inherit from `Minitest::Test`.
4. If the subject loads `src/neo.rb`, set
   `ENV['NEO_DISABLE_END'] = 'true'` **before** the require
   (`tests/neo_output_test.rb:3`).
5. If the subject is `bin/koans`, prefer the subprocess pattern via
   `Open3` rather than requiring the CLI in-process.
6. Run `bundle exec rake test` locally; CI runs the same task.

---

*Testing analysis: 2026-05-07*
