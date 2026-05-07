# Coding Conventions

**Analysis Date:** 2026-05-07

This is a teaching codebase. Conventions reflect that purpose: koan files
deliberately contain failing assertions and "fill-me-in" placeholders, while
the runner (`src/neo.rb`) and the CLI (`bin/koans`) follow conventional Ruby
style. Two distinct layers exist:

1. **Curriculum layer** (`src/about_*.rb`, `koans/about_*.rb`) — pedagogical
   Ruby with intentional placeholders.
2. **Tooling layer** (`bin/koans`, `src/neo.rb`, `rakelib/*.rake`,
   `Rakefile`) — production-style Ruby that runs and validates the
   curriculum.

## Naming Patterns

**Files:**
- Curriculum files use `snake_case` and a topical `about_` prefix:
  `src/about_strings.rb`, `src/about_pattern_matching.rb`,
  `src/about_keyword_arguments.rb`.
- Project-style koans append `_project` (or `_project_2`):
  `src/about_triangle_project.rb`, `src/about_dice_project.rb`,
  `src/about_scoring_project.rb`, `src/about_proxy_object_project.rb`.
- Test files end in `_test.rb`: `tests/check_test.rb`,
  `tests/koans_cli_test.rb`, `tests/neo_output_test.rb`.
- Rake task files use `.rake` and live in `rakelib/`:
  `rakelib/checks.rake`, `rakelib/test.rake`, `rakelib/run.rake`.
- The single CLI entrypoint has no extension: `bin/koans`.

**Classes:**
- Each koan file defines exactly one `About<Topic>` class extending
  `Neo::Koan`: `class AboutAsserts < Neo::Koan`,
  `class AboutMessagePassing < Neo::Koan`.
- Helper classes inside a koan use `CamelCase` and are nested inside the
  `About*` class: `class MessageCatcher`, `class TypicalObject`,
  `class Television` (`src/about_message_passing.rb:5`,
  `src/about_proxy_object_project.rb:121`).
- Tooling uses module-namespaced classes: `Neo::Sensei`, `Neo::Koan`,
  `Neo::ThePath`, `Neo::Color`, `Neo::Assertions` (`src/neo.rb:91-555`).

**Test methods:**
- Always start with `test_` followed by an English-style snake_case
  description of the lesson:
  `test_double_quoted_strings_are_strings`,
  `test_subclasses_can_invoke_parent_behavior_via_super`,
  `test_methods_can_be_invoked_more_dynamically`.
- The `Neo::Koan.test_pattern` regex (`src/neo.rb:525`) is `/^test_/`. Any
  instance method whose name matches becomes a step on the path.

**Variables:**
- `snake_case` for locals and instance variables.
- The pair `expected_value` / `actual_value` is used when the lesson is the
  shape of the assertion itself (`src/about_asserts.rb:36-48`).
- Top-level constants are `SCREAMING_SNAKE_CASE` (`PROGRESS_FILE_NAME`,
  `SRC_DIR`, `KOANS_DIR`, `PATH_FILE`, `DEFAULT_PROGRESS_FILE`).

## The Koan Placeholder Vocabulary

These are the most important conventions in the curriculum. They are
**solution markers** that `Rakefile` and `bin/koans` strip from `src/` to
produce the unanswered files in `koans/`.

| Placeholder | Meaning | Defined at |
|-------------|---------|------------|
| `__` | Generic value blank ("FILL ME IN" string in the koan) | `src/neo.rb:39` |
| `_n_` | Numeric blank (defaults to `999999`) | `src/neo.rb:48` |
| `___` | Error-class blank (defaults to `FillMeInError`) | `src/neo.rb:57` |
| `____` | Method-name blank — sends `method` to `self` | `src/neo.rb:67` |
| `# __` (trailing comment) | Marker that this line is part of the puzzle | stripped by `Rakefile:30` |

**Source file (`src/about_*.rb`) — answer is inside the parentheses:**
```ruby
def test_assert_equality
  expected_value = __(2)            # the answer is `2`
  actual_value = 1 + 1
  assert expected_value == actual_value
end

def test_fill_in_values
  assert_equal __(2), 1 + 1
end
```
(`src/about_asserts.rb:35-53`)

**Generated koan file (`koans/about_*.rb`) — argument and trailing `# __`
are stripped:**
```ruby
def test_assert_equality
  expected_value = __                # student must replace `__`
  actual_value = 1 + 1
  assert expected_value == actual_value
end

def test_fill_in_values
  assert_equal __, 1 + 1
end
```
(`koans/about_asserts.rb:21-39`)

**`___` for exception classes** (`src/about_exceptions.rb:62-65`):
```ruby
def test_asserting_an_error_is_raised # __
  assert_raise(___(MySpecialError)) do
    raise MySpecialError.new("New instances can be raised directly.")
  end
end
```

**`____` for method names** (`src/about_message_passing.rb:28`):
```ruby
assert mc.send("CAUGHT?".____(:downcase) )   # student writes `.downcase`
```

**`#--` / `#++` solution blocks:** `Rakefile:42-49` and `bin/koans:339-345`
strip every line between a `#--` and a `#++` marker when generating
`koans/`. This is how multi-line answers are hidden:
```ruby
def triangle(a, b, c)
  # WRITE THIS CODE
  #--
  a, b, c = [a, b, c].sort
  fail TriangleError if (a+b) <= c
  sides = [a, b, c].uniq
  [nil, :equilateral, :isosceles, :scalene][sides.size]
  #++
end
```
(`src/triangle.rb:16-24`)

In the generated file, only `# WRITE THIS CODE` survives
(`koans/triangle.rb:16-18`).

**Versioned answers:** `__(value, value19)` lets a single source file work
across Ruby versions. The first arg is the pre-1.9 answer; the second
overrides for Ruby 1.9+ (`src/neo.rb:39-45`,
`src/about_classes.rb:25`). `_n_` and `___` follow the same shape.

**Rule of thumb when editing `src/`:**
- `__(answer)` for a value blank.
- `_n_(answer)` for a numeric blank.
- `___(ErrorClass)` for an exception blank.
- `obj.____(:method)` for a method-name blank.
- Wrap full solution bodies in `#--` / `#++` so `rake gen` regenerates a
  clean exercise.

## Code Style

**Formatting:**
- No formatter is configured. No `.rubocop.yml`, no `.editorconfig`, no
  Standard Ruby. Style is by convention only.
- 2-space indentation everywhere.
- Single-line method bodies use `def ... end` rather than endless methods.
- Tooling code (`bin/koans`, `tests/*_test.rb`) opts in to
  `# frozen_string_literal: true` (`bin/koans:2`); curriculum files
  intentionally do not, because string mutation is a koan topic
  (`src/about_strings.rb:86-105`).

**Linting:**
- No linter is configured.
- The repo enforces curriculum integrity through `rake check`
  (`rakelib/checks.rake`), not style:
  - `check:abouts` — every `src/about_*.rb` is required from
    `src/path_to_enlightenment.rb`.
  - `check:asserts` — every `assert` in `src/about_*.rb` (except the
    intro and `*project*` files) contains a `__` or `_n_` placeholder, so
    no koan accidentally ships with the answer hard-coded.

## Imports & Requires

**Curriculum file header — always identical:**
```ruby
require File.expand_path(File.dirname(__FILE__) + '/neo')

class AboutXxx < Neo::Koan
  ...
end
```
(`src/about_asserts.rb:4`, `src/about_strings.rb:1`, etc.)

**Path/curriculum order is the single source of truth.** New koan files
are added by appending a line to `src/path_to_enlightenment.rb`:
```ruby
$LOAD_PATH << File.dirname(__FILE__)

require 'about_asserts'
require 'about_true_and_false'
require 'about_strings'
...
require 'about_extra_credit'
```
(`src/path_to_enlightenment.rb:1-45`). The `bin/koans` runner reads this
file with a regex (`bin/koans:239`) to determine canonical step order.

**Version-gated requires** use the `in_ruby_version` helper from
`src/neo.rb:24-26`:
```ruby
in_ruby_version("2", "3", "4") do
  require 'about_keyword_arguments'
end

in_ruby_version("2.7", "3", "4") do
  require 'about_pattern_matching'
end
```
(`src/path_to_enlightenment.rb:15-43`).

**Tooling requires** use `require_relative` and `require`:
- `bin/koans:4-6`: `require "fileutils"`, `"rbconfig"`, `"English"`.
- Tests use `require_relative "test_helper"` (`tests/check_test.rb:1`,
  `tests/koans_cli_test.rb:1`, `tests/neo_output_test.rb:1`).

## Error Handling

**Curriculum** raises and rescues errors as part of the lesson, using
`Neo::Assertions#assert_raise` and `assert_nothing_raised`
(`src/neo.rb:185-202`). These are wrappers around `begin/rescue` that
capture the exception so the lesson can inspect it:
```ruby
exception = assert_raise(___(NoMethodError)) do
  typical.foobar
end
assert_match(/foobar/, exception.message) # __
```
(`src/about_message_passing.rb:80-85`). `fail` and `raise` are taught as
synonyms (`src/about_exceptions.rb:38`).

**Tooling** uses targeted `rescue` clauses with a single-line idiom for
recoverable errors:
```ruby
def watch_interval
  Float(ENV.fetch("KOANS_WATCH_INTERVAL", "0.5"))
rescue ArgumentError
  0.5
end
```
(`bin/koans:175-179`).

For unrecoverable user input, `bin/koans` writes to `stderr` and exits
non-zero rather than raising, so the CLI surface stays predictable
(`bin/koans:36-39`, `bin/koans:128-152`):
```ruby
unless target
  warn "Usage: bin/koans reset <about_file|all>"
  return 1
end
```

The `Neo::Koan#meditate` method swallows `StandardError` and the runner's
own `FailedAssertionError` so a single failing koan does not crash the
whole walk; the failure is recorded on the step instead
(`src/neo.rb:463-477`):
```ruby
def meditate
  setup
  begin
    send(name)
  rescue StandardError, Neo::Sensei::FailedAssertionError => ex
    failed(ex)
  ensure
    begin
      teardown
    rescue StandardError, Neo::Sensei::FailedAssertionError => ex
      failed(ex) if passed?
    end
  end
  self
end
```

## Logging & User Output

**No logger.** All output is via `puts`, `print`, and `warn`.

**Color is opt-in and TTY-aware.** Use `Neo::Color.<name>(string)` rather
than raw ANSI escapes (`src/neo.rb:98-145`). Colors are disabled when
`NO_COLOR` is set, when `ANSI_COLOR` is set to a non-truthy value, or
when stdout is not a TTY:
```ruby
puts Color.green("#{label} has expanded your awareness.")
puts Color.red(indent("#{failure.class}: #{failure.message}").join)
puts Color.cyan("  You have not yet reached enlightenment.")
```
(`src/neo.rb:251`, `src/neo.rb:366`, `src/neo.rb:352`).

**Channels:**
- Progress and lesson output → `$stdout` via `puts`/`print`.
- Errors and usage messages → `$stderr` via `warn` (`bin/koans:36-39`,
  `bin/koans:128`, `bin/koans:151`).

## Comments

**Lesson commentary is the comment.** Koan files use comments as the
primary teaching medium. Three idioms recur:

1. **Section dividers** — a long `# ---...---` rule between sub-topics:
   ```ruby
   # ------------------------------------------------------------------
   ```
   (`src/about_message_passing.rb:48`,
   `src/about_inheritance.rb:57`).
2. **Pre-method narrative** — a 1-3 line comment immediately above
   `def test_*` describing the lesson:
   ```ruby
   # We shall contemplate truth by testing reality, via asserts.
   def test_assert_truth
   ```
   (`src/about_asserts.rb:8-9`). `bin/koans hint` extracts these comments
   (`bin/koans:301-318`) and shows them as a hint, so write hint-worthy
   comments above each `test_`.
3. **THINK ABOUT IT / NOTE / QUESTION** blocks — explicit reflection
   prompts that do not require a code change:
   ```ruby
   # THINK ABOUT IT:
   #
   # Why does Ruby provide both send and __send__ ?
   ```
   (`src/about_message_passing.rb:36-39`,
   `src/about_constants.rb:69-70`).

**`# __` end-of-line marker** flags an `assert` that has no `__()` blank
in arguments but is still a puzzle. The marker is stripped from `koans/`
(`Rakefile:30`) so the student sees only the assertion. It also satisfies
`rake check:asserts`, which would otherwise complain that the assert has
no placeholder (`rakelib/checks.rake:27-32`):
```ruby
assert mc.caught?           # __
```
(`src/about_message_passing.rb:14`).

**Tooling comments** are sparse and explain non-obvious behaviour
(`src/neo.rb:99` ("shamelessly stolen (and modified) from redgreen"),
`src/neo.rb:411-412` (zen-statement attribution)).

## Function & Method Design

**Curriculum:**
- One concept per `test_` method. Keep the method body small enough to
  read top-to-bottom (typically 3-8 lines).
- Helper classes/modules used by the lesson go inside the same `About*`
  class so they are scoped to the koan
  (`src/about_message_passing.rb:5-9`,
  `src/about_proxy_object_project.rb:121-135`).
- When an example must reopen a class to demonstrate a concept, do it
  inside the `About*` class and add a comment explaining the reopen
  (`src/about_message_passing.rb:50-54`,
  `src/about_open_classes.rb:18-22`).

**Tooling (`bin/koans`):**
- Methods are short and dispatched from a `case` in `RubyKoansCLI.call`
  (`bin/koans:16-41`); each command becomes its own method
  (`walk`, `watch`, `list`, `next_step`, `hint`, `reset`).
- Methods return integer exit codes so the dispatcher can `exit` on them
  uniformly (`bin/koans:43-46`, `bin/koans:163-169`).
- Class-level `class << self` block on `RubyKoansCLI` keeps everything as
  module methods — no instances needed (`bin/koans:15`).

## Module Design

**`Neo` namespace** (`src/neo.rb:91-555`) wraps all runner code:
`Neo::Color`, `Neo::Assertions`, `Neo::Sensei`, `Neo::Koan`,
`Neo::ThePath`, `Neo.simple_output`. The only top-level helpers are the
intentionally-global placeholder methods `__`, `_n_`, `___`, and the
extension to `Object#____` (`src/neo.rb:39-76`) — these must be globally
available because every koan body uses them.

**No barrel files** and no autoloading. Each koan requires `neo` directly
(`require File.expand_path(File.dirname(__FILE__) + '/neo')`) and the
runner relies on `Neo::Koan.inherited` (`src/neo.rb:481-483`) to pick up
new subclasses as files are loaded.

**Custom DSL exposure:** `Neo::Koan#testmethods` is populated by the
`method_added` hook (`src/neo.rb:485-487`). Adding `def test_foo` inside
any subclass automatically registers `:test_foo` as a step. There is no
explicit `test`-block macro.

## Where Conventions Differ Between `src/` and `koans/`

`koans/` is a **derived directory**. Do not edit it by hand if you intend
the change to persist — `rake gen` (or `bin/koans reset all`) will
overwrite it. The differences are mechanical:

| In `src/about_*.rb` | In `koans/about_*.rb` |
|---------------------|-----------------------|
| `__(2)` | `__` |
| `_n_(7)` | `_n_` |
| `___(NoMethodError)` | `___` |
| `obj.____(:downcase)` | `obj.____` |
| `# __` at end of line | (line keeps everything except `# __`) |
| Lines between `#--` and `#++` | (removed entirely) |

The transformation lives in `Koans.remove_solution`
(`Rakefile:24-32`) and is duplicated as
`RubyKoansCLI.remove_solution` (`bin/koans:347-354`) for
`bin/koans reset`. Keep the two implementations in sync when changing
either.

---

*Convention analysis: 2026-05-07*
