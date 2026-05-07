# Ruby Path *(working title — final name TBD)*

## What This Is

A modern, Rustlings-inspired learning tool for Ruby 4+ that replaces the legacy Edgecase Ruby Koans curriculum. The audience is people who already program in another language and want to learn idiomatic Ruby today. Learners install a gem, run `<cli> init`, and progress through exercises in their editor while a watcher gives live feedback — they read real Ruby errors, modify real code, use Minitest, and get exposed to the modern toolchain (Bundler, debug.gem, RuboCop, error_highlight) instead of filling `__` placeholders inside test methods.

## Core Value

**A self-paced learner can install the tool, work through every exercise, and finish feeling they understand modern Ruby (3.x/4.x) the way the community actually writes it today.** If everything else fails, this single experience must work.

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

(None yet — the existing Edgecase Ruby Koans curriculum is the *starting material*, not validated v1 deliverable. Everything is being redesigned.)

### Active

<!-- Current scope. Building toward v1. -->

**Infrastructure & CLI**

- [ ] Install via `gem install <name>` and bootstrap a learner workspace via `<cli> init` (Rustlings-style)
- [ ] CLI provides primary commands: `init`, `run` (or default), `watch`, `hint`, `solution`, `list`, `reset`
- [ ] File watcher reruns the current exercise on save and shows compiler/runtime errors directly
- [ ] Runner executes exercises with native Ruby tooling (`ruby`/`bundle exec`) — no custom Neo-style mini-framework as the primary path
- [ ] Progress is tracked locally so learners can stop and resume
- [ ] Exercises live in `exercises/<topic>/<exercise>.rb`; reference solutions in `solutions/<topic>/<exercise>.rb` start as empty stubs and are filled in *after* the learner solves the exercise (Rustlings-style)
- [ ] Works on Ruby 4.0+ only — installation guides learners to mise/rbenv/asdf if missing

**Curriculum — classics modernized**

- [ ] Fundamentals refreshed in the new style (asserts, true/false, strings, symbols, arrays, hashes, methods, blocks, exceptions, classes, modules, inheritance, scope, constants, regex, control flow, objects, nil, iteration, message passing, open classes, to_str)
- [ ] Test-driven mini-projects refreshed (triangle, scoring/Greed, dice, proxy object) with proper Minitest, deterministic RNG where needed, and `respond_to_missing?`/`public_send`/`...` forwarding where appropriate
- [ ] All exercises use modern hash syntax (`{key: value}`), `File.open`, idiomatic Ruby 3+/4 patterns

**Curriculum — Ruby 3+/4 modern topics**

- [ ] Modern keyword arguments (separation, `**nil`, `**`, anonymous args, `...` forwarding, `ruby2_keywords`, leading args)
- [ ] Pattern matching (`case/in`, one-line, find pattern, pin operator, `deconstruct`/`deconstruct_keys`, integration with `Data`)
- [ ] Modern blocks (`_1`/`_2`, `it` from Ruby 3.4, lambdas vs procs, block forwarding, anonymous block arg)
- [ ] `Data` and value objects (`Struct` vs `Data`, immutability, `with`, equality, pattern matching integration)
- [ ] Modern regex (`match?`, named captures, `Regexp.timeout`, ReDoS mitigation, `MatchData#byteoffset`)

**Curriculum — toolchain & runtime**

- [ ] Ruby tooling: Bundler/Gemfile, `bundle exec`, Minitest deeper dive, RuboCop basics, debug.gem, error_highlight, syntax_suggest, Prism (read-only awareness)
- [ ] RSpec exposure section (optional/advanced) — alternative DSL contrast against Minitest
- [ ] Concurrency: Fiber Scheduler, Ractor, shareability, `Ractor::Port`, practical limits
- [ ] Runtime: YJIT/ZJIT awareness, RubyGems/Bundler 4, default vs bundled gems, `Set` and `Pathname` as core classes, Ruby Box

**Quality & polish**

- [ ] Hint system per exercise — progressive static hints (no LLM dependency)
- [ ] Each exercise has clear acceptance criteria written into its prose so learners know when they're "done"
- [ ] CI runs the full curriculum on Ruby 4 to guard regressions
- [ ] README + install instructions tested on Linux and macOS
- [ ] Naming, branding, and final identity (replaces "Ruby Path" working title)

### Out of Scope

- **Backwards compatibility with Ruby ≤ 3.x runtime** — Ruby 4 only; the tool tells learners to install Ruby 4 if missing. Reason: explicit decision to teach modern idioms without conditional gates that confused the original Koans.
- **JRuby/TruffleRuby/MRuby** — focus is CRuby. Reason: scope and toolchain assumptions (YJIT/ZJIT, Fiber Scheduler) target CRuby; multi-VM curriculum is a follow-up.
- **Built-in LLM/AI features in the product** — no `<cli> ask` or runtime LLM calls. Reason: Rustlings-spirit, autocontained gem; LLMs were used during development, not at runtime.
- **PT-BR or multilingual curriculum in v1** — content ships in English. Reason: open-source Ruby community runs in English; localization is a v2/community concern.
- **Web UI / browser-based runner** — CLI + editor only. Reason: realism is the point; learners should use real tools.
- **Java interop koans (`about_java_interop.rb`)** — dropped entirely. Reason: JRuby is out of scope.
- **Edgecase Neo runner mini-framework** — replaced by Minitest. Reason: a primary goal of this overhaul is exposing learners to the real Ruby ecosystem.
- **The `koans/`, `src/`, `tests/`, `download/`, `keynote/`, `DEPLOYING` legacy assets remaining post-v1** — they are starting material, not deliverable. Reason: gradual replacement; once new infra and curriculum cover their concepts, the legacy goes away.

## Context

**Repository state.** This repo started as an Edgecase Ruby Koans clone. The existing assets (`koans/`, `src/`, `tests/`, `Rakefile`, `koans.watchr`, `bin/koans`) are the starting point but are being replaced gradually on `master`. The recent commits added a modern `bin/koans` CLI and a `koans.watchr` flow — those are the embryo of the new CLI/watcher and may inform the design but are not the final shape.

**Codebase map.** Up-to-date analysis lives in `.planning/codebase/` (STACK, ARCHITECTURE, STRUCTURE, CONVENTIONS, TESTING, INTEGRATIONS, CONCERNS) and was refreshed at the start of this initialization.

**Source documents.** The user provided a 367-line context document (`ruby-koans-overhaul-context.md`) containing two LLM-assisted analyses: (1) a pedagogical comparison between Ruby Koans and Rustlings, and (2) a Ruby-4 modernization audit, file by file. These are the authoritative source-of-intent and should be re-read by every planning agent for any phase that touches curriculum design or modernization decisions.

**Reference projects.** The user has a local Rustlings checkout at `~/dev/personal/rustlings/` — the canonical reference for CLI shape, exercise/solution layout, watcher behavior, and progressive hint design. Solutions in Rustlings are *empty stubs* that the CLI fills in with the official solution after the learner solves the exercise; this design is being adopted here.

**Ruby version assumptions.** Ruby 4.0 was released 2025-12-25 and Ruby 4.0.3 followed on 2026-04-21. The latest mainstream Ruby is the target. Some core-class additions (`Set`, `Pathname`, RubyGems/Bundler 4, ZJIT, Ruby Box) are 4.0-specific and must be reflected in the curriculum.

**User profile.** The maintainer is not a senior Rubyist. Decisions should be evidence-based — backed by official Ruby release notes, community idioms, and the Rustlings reference — not by guesswork. Research-before-planning is a soft requirement for any curriculum-design phase.

## Constraints

- **Tech stack**: Ruby 4.0+, Bundler-managed gem, Minitest as the primary test framework, no Rails — Reason: the product is itself a small Ruby gem; ecosystem alignment with what learners will be exposed to.
- **Distribution**: Published as a RubyGem with a `<cli> init` bootstrap — Reason: matches Rustlings UX expectation and is the lowest-friction install path for learners on any platform with Ruby installed.
- **Audience-driven curriculum tone**: assume the learner already programs (any language) but does not know Ruby — Reason: cuts content describing universal concepts (variables, conditionals as a foundation) and frees space for Ruby-specific idioms.
- **No LLM/AI runtime dependency** — Reason: portability, offline use, no API keys, lower long-term maintenance burden.
- **Single-language curriculum (English) for v1** — Reason: maintenance cost; PT-BR comms with the maintainer happen separately from the product.
- **Solutions are local-first and "earned"** — Reason: spoiler control; matches Rustlings; preserves the contemplative spirit of the original Koans without the "fill the blank in the test" mechanic.
- **Maintainer scarcity** — only one developer (you) plus LLM assistance — Reason: roadmap should bias toward fewer, larger automated tasks rather than many small ones requiring human review; planning must include extensive research phases up front to compensate for limited Ruby seniority.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Replace Ruby Koans gradually on `master` (no fork, no parallel track) | Simpler git history, single source of truth, forces commitment to the new design | — Pending |
| All three "frentes" (content, didactics, infrastructure) attacked in parallel within v1 | Forces integration from day one and avoids rework from sequencing infra → content as separate releases | — Pending |
| Audience: developer who already programs but does not know Ruby (not absolute beginner, not Rubyist upgrading) | Matches Rustlings positioning; lets curriculum focus on Ruby-specific idioms | — Pending |
| Curriculum language: English for product; PT-BR for maintainer-Claude conversation | Aligns with Ruby OSS norms; preserves comfort in planning conversations | — Pending |
| Identity: new name with zen/contemplative spirit (no "Koans" in the name) | "Ruby Koans" implies the Edgecase mechanics that this project deliberately abandons | — Pending |
| Test framework for exercises: Minitest as primary, RSpec as optional/exposure section | Minitest ships with Ruby; minimum-DSL surface for fundamentals; RSpec exposure satisfies job-market reality | — Pending |
| Ruby support: Ruby 4.0+ only (no LTS branching) | Avoids the original Koans' version-gate maze; keeps curriculum aligned with current idioms | — Pending |
| Distribution: published gem with `<cli> init` bootstrap | Matches Rustlings UX; one-line install for any Ruby learner | — Pending |
| Solutions: Rustlings-style — `solutions/<topic>/<exercise>.rb` ships as empty stubs; CLI auto-fills the official solution after the exercise is solved | Spoiler control; preserves contemplative spirit; encourages re-solving from scratch on a fresh `init` | — Pending |
| No LLM/AI integration in the product runtime | Rustlings spirit; offline-friendly; no API key management; uses LLMs only during development of the curriculum | — Pending |
| v1 success criterion: an external learner can complete the full curriculum and feels they learned modern Ruby | User-outcome, not technical-checkbox; this drives every prioritization tradeoff in v1 | — Pending |
| v1 scope = entire content of `ruby-koans-overhaul-context.md` (classics refreshed + modern Ruby topics + tooling + concurrency + runtime) | Maintainer prefers one large milestone with many small phases over multiple smaller releases — gives a "complete product" at v1 instead of a partial shipping product | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-05-07 after initialization*
