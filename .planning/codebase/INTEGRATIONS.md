# External Integrations

**Analysis Date:** 2026-05-07

## APIs & External Services

This is an offline learning project. There are **no production APIs, no SaaS clients, no SDK calls, and no network I/O at runtime**. The only network-touching operations are dev/release tooling (gem install, scp deploy, GitHub Actions).

**Gem registry:**
- `rubygems.org` — declared as the source in `Gemfile:1` (`source "https://rubygems.org"`) and `Gemfile.lock:2`. Bundler fetches `minitest`, `rake`, `drb`, `prism` from here.

**Optional Java runtime (JRuby):**
- Loaded only under JRuby (`src/about_java_interop.rb:3` `include Java`). Pulls in `java.util.ArrayList`, `java.util.TreeSet`, `java.lang.String` from the host JVM. This is a learning exercise, not an integration with an external service.

## Data Storage

**Databases:**
- None.

**File Storage:**
- Local filesystem only. The CLI persists progress to `koans/.path_progress` (`bin/koans:13`), overridable via `KOANS_PROGRESS_FILE`. The runtime also writes the same file from `Neo::Sensei#add_progress` (`src/neo.rb:217-225`) using the constant `PROGRESS_FILE_NAME = '.path_progress'` resolved relative to the working directory.
- `download/rubykoans.zip` is produced by `rake package` and committed to the repo so GitHub serves it as the public download (`DEPLOYING:1-12`).

**Caching:**
- None.

## Authentication & Identity

**Auth Provider:**
- None. There are no users, sessions, tokens, or credentials in the application code.
- The only credentialed step is the legacy `rake upload` task (`Rakefile:94-97`), which shells out to `scp #{ZIP_FILE} linode:sites/onestepback.org/download`. That host alias is expected to be configured in the operator's `~/.ssh/config`. No credentials live in the repo.

## Monitoring & Observability

**Error Tracking:**
- None. Errors surface to STDOUT through `Neo::Sensei#guide_through_error` (`src/neo.rb:362-375`) and through Minitest output for the internal test suite.

**Logs:**
- `puts`/`print` to STDOUT only. ANSI colors are added by `Neo::Color` (`src/neo.rb:98-145`) and respect the `NO_COLOR` and `ANSI_COLOR` environment variables.

## CI/CD & Deployment

**Hosting:**
- Static zip download. The README/DEPLOYING files describe a download button on `rubykoans.com` that points at `download/rubykoans.zip` in the GitHub repo (`DEPLOYING:3-5`). The fork itself is not hosted as an application.

**CI Pipeline:**
- GitHub Actions — `.github/workflows/ci.yml`.
  - Trigger: `on: [push, pull_request]` (`ci.yml:3`).
  - Runner: `ubuntu-latest`.
  - Matrix: Ruby `3.2`, `3.3`, `3.4` (`ci.yml:11`), `fail-fast: false`.
  - Actions used:
    - `actions/checkout@v4` (`ci.yml:15`).
    - `ruby/setup-ruby@v1` with `bundler-cache: true` (`ci.yml:18-21`) — installs Ruby and runs `bundle install` with caching.
  - Command: `bundle exec rake test check` (`ci.yml:24`) — runs Minitest suite plus the `check:abouts` and `check:asserts` consistency tasks (`rakelib/checks.rake:48`).

**Deployment (legacy, manual):**
- `rake zip` rebuilds `download/rubykoans.zip` (`Rakefile:81-89`).
- `rake upload` ships the zip to a Linode-hosted SSH alias `linode:sites/onestepback.org/download` (`Rakefile:94-97`). This is upstream-era tooling and is not used by this fork's CI; nothing in `.github/workflows/ci.yml` invokes it.

## Environment Configuration

**Required env vars:**
- None are required for normal use. All variables are optional toggles (see STACK.md → Configuration).

**Secrets location:**
- No secrets in the repo. No `.env*` files exist. `.gitignore:3` lists `.project_env.rc` (none present), and there is no `.env`, `credentials.*`, or key file. SSH access for `rake upload` relies on the operator's local SSH config.

## Webhooks & Callbacks

**Incoming:**
- None.

**Outgoing:**
- None.

## Developer Tooling Integrations

These are local development conveniences, not service integrations, but they are the closest thing this repo has to "integrations" and are useful to track.

**File-watching loop (built in):**
- `bin/koans watch` (`bin/koans:49-70`) — built-in poller. Stats `koans/*.{rb,txt}` every `KOANS_WATCH_INTERVAL` seconds (default `0.5`) and re-runs the path on any change. **No external watcher gem required.**
- `rake watch` (`Rakefile:73-75`) is an alias that just shells out to `ruby bin/koans watch`.

**Watchr DSL (legacy / optional):**
- `koans.watchr` (top level) and `koans/koans.watchr` (shipped copy) — 11-line scripts using the `watchr` gem's DSL: `watch(%r{^koans/.*\.(rb|txt)$}) { run_koans }`. Not declared in the `Gemfile`; learners must install `watchr` themselves if they want to use it. The README explicitly notes that `bin/koans watch` "does not need an extra watcher gem" (`README.rdoc:73-74`).

**Editor / RDoc:**
- README is `.rdoc` format (`README.rdoc`), rendered natively by GitHub. No Markdown linting or doc generator is wired up.

**Keynote slide deck:**
- `keynote/RubyKoans.key` — a presentation file shipped alongside the source. No build integration.

## Repository Artifacts Treated as Integration Surfaces

- `download/rubykoans.zip` — committed binary artifact used as a public download. `Rakefile:80-89` regenerates it from `KOAN_FILES`. Treat this as a release output of the `rake package` "integration."
- `koans/.path_progress` — runtime-managed progress file. Persisted across runs by `Neo::Sensei` (`src/neo.rb:217-238`) and read by `bin/koans next`/`hint`/`list` (`bin/koans:200-204`). Listed in `.gitignore:4` so it never gets committed.

---

*Integration audit: 2026-05-07*
