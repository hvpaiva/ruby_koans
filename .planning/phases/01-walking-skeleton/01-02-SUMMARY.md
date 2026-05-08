---
phase: 01-walking-skeleton
plan: 02
subsystem: infra
tags: [listen, ruby4, watcher-spike, github-actions, watch-05]

requires:
  - phase: 01-walking-skeleton/01-01
    provides: rubykoans.gemspec with `listen ~> 3.10` runtime dep, Gemfile.lock with listen 3.10.0 resolved, .github/workflows/ci.yml as a sibling reference shape
provides:
  - WATCH-05 spike scaffolding: standalone Ruby script + GHA workflow that answer "does listen 3.10 fire events on Ruby 4?" on Linux and macOS
  - Local-Linux verdict captured (Ruby 4.0.2, listen 3.10.0, x86_64-linux): GREEN — listen fired an event within budget on the developer's machine
affects: [02-watcher-and-watch-loop]

tech-stack:
  added: []
  patterns:
    - "One-off spike directory (`spike/`) with explicit lifecycle README — file is git-removed once the question is answered"
    - "Companion one-off GHA workflow alongside primary `ci.yml`, distinct file, no overlap"
    - "Spike script is exit-code-is-truth: 0 = pass, 1 = fail; Listen.to + Dir.mktmpdir + listener.start/stop + 1.0s polling budget"

key-files:
  created:
    - spike/listen_check.rb
    - spike/README.md
    - .github/workflows/spike-listen.yml
  modified: []

key-decisions:
  - "Spike script written verbatim to CONTEXT.md D-12 spec (~50 lines including header comments): Listen.to(tmp, latency: 0.2), wire-up sleep 0.3s, file write, 1.0s polling budget, listener.stop, exit 0/1"
  - "GHA workflow uses `workflow_dispatch` + `push: paths: [spike/**, .github/workflows/spike-listen.yml]` — runs only when the spike file changes or on manual trigger; does NOT gate normal CI"
  - "Local Linux leg ran on Ruby 4.0.2 (the developer's mise-installed stable). Plan accepted this in Task 3: `4.0.0/4.0.1/4.0.2 are also acceptable for the spike but capture the actual version`."
  - "Verdict file (`01-02-LISTEN-SPIKE-RESULT.md`) is NOT yet written — Task 4 is a `checkpoint:human-verify` and requires the macOS GHA leg's outcome before the verdict can be recorded. This SUMMARY documents partial completion (Tasks 1–3) pending checkpoint resume."

patterns-established:
  - "Spike scaffolding lifecycle: `spike/<name>.rb` + `.github/workflows/spike-<name>.yml` + README documenting deletion gate. Both files are deleted in a single commit once the verdict is acted on."
  - "Explicit Listen API surface for Phase 2 to reuse: `Listen.to(dir, latency: 0.2) { |modified, added, removed| ... }.start` + `.stop`. `latency:` parameter stays at 0.2 (not the gem default 0.25) so Phase 2's debounce window matches the proven spike."

requirements-completed: []  # WATCH-05 is partially advanced; full closure requires the verdict file (Task 4 — pending human checkpoint).

duration: 5min
completed: 2026-05-07
---

# Phase 01 Plan 02: WATCH-05 Listen Spike Summary

**WATCH-05 spike scaffolding shipped (script + GHA workflow); local Linux leg PASSED (Ruby 4.0.2, x86_64-linux); macOS GHA leg pending human-verify checkpoint.**

## Status: PARTIAL — Awaiting Checkpoint

Tasks 1, 2, and 3 are complete and committed. **Task 4 is a `checkpoint:human-verify` that has not yet been completed** because it requires:

1. The developer to push the spike workflow to GitHub (this commit triggers it via `push: paths: [spike/**]`).
2. The developer to wait for the GHA macOS leg to finish (~3–5 minutes).
3. The developer to read both leg results and write the verdict file at `.planning/phases/01-walking-skeleton/01-02-LISTEN-SPIKE-RESULT.md`.

The plan's `<verify>` automation for Task 4 (asserting the verdict file exists with correct frontmatter) cannot pass until step 3 is done. **This SUMMARY documents the work-to-date; a continuation agent (or the developer manually) writes the verdict file once the macOS leg lands.**

## Performance

- **Duration:** ~5 min (worktree wall clock; excludes the GHA macOS run that has not happened yet)
- **Started:** 2026-05-08T00:23:00Z
- **Paused at checkpoint:** 2026-05-08T00:28:38Z
- **Tasks committed:** 2 of 4 (Task 3 produced no file changes; Task 4 is the pending checkpoint)
- **Files created:** 3

## Accomplishments

- **Task 1:** `spike/listen_check.rb` (50 lines, exit-code-is-truth) and `spike/README.md` (documents lifecycle). Script parses cleanly, exercises `Listen.to`, `Dir.mktmpdir`, `listener.start/stop`, and has explicit `exit 0` / `exit 1` paths.
- **Task 2:** `.github/workflows/spike-listen.yml` with matrix `[ubuntu-latest, macos-latest]` × `ruby-version: 4.0.3`, `fail-fast: false`, single `bundle exec ruby spike/listen_check.rb` step.
- **Task 3:** Local Linux leg ran on Ruby 4.0.2 + listen 3.10.0 → **PASS** (event fired within 1.0s budget). Output captured in `/tmp/listen-spike-local.txt`.

## Task Commits

1. **Task 1: Spike script + README** — `777f576` (feat)
   `feat(01-02): add WATCH-05 listen spike script`
2. **Task 2: GHA workflow** — `139f64f` (feat)
   `feat(01-02): add one-off GHA workflow for WATCH-05 spike`
3. **Task 3: Local Linux leg execution** — _no commit_ (no source change; runtime-only output captured at `/tmp/listen-spike-local.txt`)
4. **Task 4: Verdict recording** — _PENDING_ (checkpoint:human-verify; requires GHA macOS leg result)

**Plan metadata commit:** _will be made after Task 4 completes._

## Files Created

- `spike/listen_check.rb` — standalone Ruby script: creates a tmpdir, starts `Listen.to(...)`, writes a file, polls for the event within 1.0s, calls `listener.stop`, exits 0 on event-received, 1 otherwise.
- `spike/README.md` — documents the spike directory's lifecycle: scaffolding deleted via `git rm` once WATCH-05 closes.
- `.github/workflows/spike-listen.yml` — one-off GHA workflow: matrix `[ubuntu-latest, macos-latest]` × `ruby-version: 4.0.3`, runs the spike script via `bundle exec ruby`. Triggers on `workflow_dispatch` and on `push` to `spike/**` or the workflow file itself.

## Local Linux Leg Result

Captured by Task 3 in `/tmp/listen-spike-local.txt`:

```
spike_exit_code=0
ruby_version=ruby 4.0.2 (2026-03-17 revision d3da9fec82) +PRISM [x86_64-linux]
platform=Linux 6.17.0-22-generic
```

`bundle exec gem list listen` confirmed listen 3.10.0 (the same version pinned in Plan 01's `Gemfile.lock`).

The spike script printed:
```
[spike] listen fired an event within budget (latency=0.2s, budget=1.0s) on x86_64-linux / Ruby 4.0.2
```

**Local Linux verdict (preliminary):** `GREEN` — listen 3.10 fires events on Ruby 4.0.2 within budget. The Ruby 4.0.3 GHA Linux leg is expected to confirm this; if it disagrees the verdict file (Task 4) records both data points.

## Decisions Made

- **Script content:** written verbatim to PATTERNS.md §`spike/listen_check.rb`'s recommended shape (50 lines including header comments — within the 25–60 sweet spot the verify automation enforces).
- **Workflow triggers:** `workflow_dispatch` (manual) + `push: paths: [spike/**, .github/workflows/spike-listen.yml]` — keeps the spike out of the normal CI gating loop. The path filter means this commit (which adds `spike/listen_check.rb`, `spike/README.md`, and the workflow file) will trigger the workflow when pushed.
- **No commit for Task 3:** Task 3's only output is a runtime-captured exit code at `/tmp/listen-spike-local.txt`. No tracked-file changes. Per task_commit_protocol "If there are no changes to commit, do not create an empty commit."
- **No verdict file:** Task 4 is the verdict-recording task and is `checkpoint:human-verify`. The verdict file (`01-02-LISTEN-SPIKE-RESULT.md`) cannot be written until the GHA macOS leg has run; it is intentionally NOT written by this agent.

## Deviations from Plan

None — plan executed exactly as written through Task 3. Task 4 paused at its checkpoint as designed.

## Issues Encountered

- **Worktree base mismatch on agent start.** The worktree's HEAD pointed at `26748fd` (the Edgecase legacy commit) instead of the expected `c01161c` (the parent's Plan 01 merge). Resolved per `<worktree_branch_check>` protocol with `git reset --hard c01161c0f6587fc19537799fa94ecee0ba389d35`. After reset, `Gemfile.lock` (with listen 3.10.0) and `rubykoans.gemspec` (with `listen ~> 3.10` runtime dep) were present, so Plan 01's outputs were available for the spike's `bundle exec` invocations.
- **GitHub Actions security hook on `Write`.** The pre-tool hook flagged the YAML workflow file with a generic command-injection reminder. Reviewed: the workflow uses only `${{ matrix.os }}` (a safe matrix variable) and a static `run:` string. No untrusted input reaches any `run:` step. Added a comment in the workflow file explicitly documenting the security review. Re-write succeeded.
- **Local Ruby is 4.0.2, not 4.0.3.** The GHA matrix tests 4.0.3 explicitly; the local leg ran on the developer's installed 4.0.2. Plan Task 3 explicitly accepts this: `4.0.0/4.0.1/4.0.2 are also acceptable for the spike but capture the actual version in the verdict document so Phase 2 knows the data point.` Captured in `/tmp/listen-spike-local.txt` for Task 4 to incorporate.

## Pending Work — For Continuation Agent or Developer

1. Push this branch / merge to master so the GHA workflow has the spike file to run against.
2. Trigger the workflow (manually via Actions tab, OR let the `push: paths: [spike/**]` trigger fire).
3. Wait ~3–5 minutes for both legs.
4. Read each leg's exit status:
   - Both green → verdict `LISTEN_OK`.
   - Linux green, macOS red → verdict `LISTEN_FALLBACK` (Phase 2 defaults `--polling` on for macOS).
   - Linux red → verdict `LISTEN_FAIL_LINUX` (file an issue against `guard/listen`; Phase 2 cannot use listen).
5. Write `.planning/phases/01-walking-skeleton/01-02-LISTEN-SPIKE-RESULT.md` with the schema specified in Task 4's `<action>` block (frontmatter must contain `verdict`, `gha_run_url`, `linux_local_exit`, `linux_gha_exit`, `macos_gha_exit`, `local_ruby_version`, `recorded_at`; body has three sections — `## Verdict`, `## Phase 2 implication`, `## Cleanup decision`).
6. Update this SUMMARY's `## Status` and `requirements-completed` once the verdict is recorded.

## Threat Flags

None. The spike script writes only to `Dir.mktmpdir`-managed paths (auto-cleaned). The GHA workflow has no untrusted-input surface. STRIDE register in the plan's `<threat_model>` documents the four reviewed threats (T-02-01 .. T-02-04) — all dispositioned `mitigate` or `accept` with mitigations in place (`Dir.mktmpdir` for tampering; `listener.stop` for DoS).

## Next Phase Readiness

- **For the rest of Phase 1:** D-13 says "Whatever the spike's outcome, Phase 1's deliverable still ships." Plans 03 and 04 do NOT consume the verdict file; they can proceed in parallel.
- **For Phase 2:** the verdict file (when written) is the authoritative answer to "does listen work on Ruby 4.0.3?". Phase 2 planning reads it directly. Until then, Phase 2 should plan as if the answer is `LISTEN_OK` (the local Linux signal is positive) but defer commitment until the macOS leg returns.

## Self-Check: PARTIAL

- spike/listen_check.rb: FOUND
- spike/README.md: FOUND
- .github/workflows/spike-listen.yml: FOUND
- Task 1 commit `777f576`: FOUND
- Task 2 commit `139f64f`: FOUND
- /tmp/listen-spike-local.txt: FOUND (`spike_exit_code=0`)
- `.planning/phases/01-walking-skeleton/01-02-LISTEN-SPIKE-RESULT.md`: **MISSING** — intentionally pending checkpoint resume (Task 4).

---

*Phase: 01-walking-skeleton*
*Plan: 02 — WATCH-05 listen spike*
*Status as of this SUMMARY: 3 of 4 tasks complete; Task 4 awaiting `checkpoint:human-verify`.*
*Paused: 2026-05-08*
