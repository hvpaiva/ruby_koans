# External Integrations

**Analysis Date:** 2026-05-07

## APIs & External Services

**Package Registry:**
- RubyGems - Source for runtime/development gems.
  - SDK/Client: Bundler reading `Gemfile` and `Gemfile.lock`.
  - Auth: None detected; `Gemfile:1` uses public `https://rubygems.org` and no `.npmrc`, `.gem/credentials`, `.env`, or package-token file is present in the repository root.
  - Files: `Gemfile`, `Gemfile.lock`.

**Source Control / Issue Tracking:**
- GitHub - Repository hosting, issue tracker, pull request CI triggers, and distribution workflow target.
  - SDK/Client: Git and GitHub Actions; no GitHub API client library detected.
  - Auth: Handled outside the codebase by Git/GitHub Actions credentials; no repository-stored token detected.
  - Files: `.github/workflows/ci.yml`, `README.rdoc`, `DEPLOYING`.
  - Practical references: `README.rdoc:130` points to the issue tracker; `DEPLOYING:8-10` documents `git add download` and `git push` for publishing the ZIP artifact.

**CI Runner Services:**
- GitHub Actions - Runs internal tests and consistency checks on pushes and pull requests.
  - SDK/Client: Workflow actions `actions/checkout@v4` and `ruby/setup-ruby@v1` in `.github/workflows/ci.yml:14-21`.
  - Auth: GitHub-provided workflow token only; no explicit secret usage detected in `.github/workflows/ci.yml`.
  - Command: `bundle exec rake test check` in `.github/workflows/ci.yml:23-24`.

**Distribution / Upload:**
- SSH/SCP target `linode:sites/onestepback.org/download` - Legacy upload target for `download/rubykoans.zip`.
  - SDK/Client: System `scp` command invoked from `Rakefile:94-97`.
  - Auth: Local SSH configuration/keys outside the repository; no private key or credential file is stored in the repo.
  - Use carefully: `rake upload` depends on `rake package` and shells out to `scp`, so it requires developer machine credentials and network access.

**Reference Links Only:**
- External learning/reference URLs are included in documentation and comments but are not called by application code.
  - Files: `README.rdoc:113-124`, `src/neo.rb:411-413`, `src/about_triangle_project_2.rb:14`, `src/about_methods.rb:130`.
  - Runtime behavior: no HTTP client imports such as `net/http`, `open-uri`, Faraday, or Rack clients are detected in source files.

## Data Storage

**Databases:**
- Not detected.
  - Connection: Not applicable.
  - Client: Not applicable.
  - Files: No `pg`, `mysql`, `sqlite`, ActiveRecord, Sequel, Redis, or database configuration files detected in `Gemfile`, `Gemfile.lock`, `src/`, `bin/`, `tests/`, or `rakelib/`.

**File Storage:**
- Local filesystem only.
  - Generated learner files are written from `src/` to `koans/` by `Rakefile:112-115` and `bin/koans:329-345`.
  - Progress is stored in `koans/.path_progress` by `src/neo.rb:217-238` and read by `bin/koans:196-204`.
  - ZIP distribution artifact lives at `download/rubykoans.zip`, configured by `Rakefile:13` and produced by `Rakefile:80-92`.
  - Temporary test progress files are created under system temp directories by `tests/koans_cli_test.rb:18-24`.

**Caching:**
- GitHub Actions Bundler cache only.
  - CI cache is enabled by `bundler-cache: true` in `.github/workflows/ci.yml:17-21`.
  - No application-level cache, Redis, Memcached, or local cache directory is detected.

## Authentication & Identity

**Auth Provider:**
- Not applicable.
  - Implementation: This repository is a local Ruby exercise runner and build/test project, not a user-facing service.
  - Files: No authentication middleware, OAuth/JWT libraries, sessions, users, or credentials configuration detected in `Gemfile`, `src/`, `bin/`, `tests/`, or `rakelib/`.

**Developer Credentials:**
- SSH credentials are external to the repository for `rake upload`.
  - Implementation: `Rakefile:94-97` uses `scp download/rubykoans.zip linode:sites/onestepback.org/download`.
  - Repository handling: no SSH private key, `.netrc`, `.env`, or cloud credential file detected.

## Monitoring & Observability

**Error Tracking:**
- None.
  - No Sentry, Honeybadger, Rollbar, OpenTelemetry, StatsD, or similar dependency appears in `Gemfile` or `Gemfile.lock`.

**Logs:**
- Console output only.
  - Koan runtime status, progress, and failure guidance are printed to stdout by `src/neo.rb:264-375`.
  - CLI status/help output uses `puts` and `warn` in `bin/koans`.
  - Rake checks write status with `puts` in `rakelib/checks.rake:7-15` and `rakelib/checks.rake:20-43`.

## CI/CD & Deployment

**Hosting:**
- GitHub repository for source and ZIP artifact distribution.
  - Files: `DEPLOYING:1-12` describes updating the ZIP in `download/` and pushing it.
- Legacy web-server upload target via SSH/SCP is present in `Rakefile:94-97`.

**CI Pipeline:**
- GitHub Actions.
  - Workflow: `.github/workflows/ci.yml`.
  - Triggers: `push` and `pull_request` from `.github/workflows/ci.yml:3`.
  - Matrix: Ruby 3.2, 3.3, and 3.4 from `.github/workflows/ci.yml:10-12`.
  - Verification: `bundle exec rake test check` from `.github/workflows/ci.yml:23-24`.

**Deployment:**
- Package deployment is artifact-based, not service-based.
  - Build: `rake package` creates `download/rubykoans.zip` using `Rakefile:80-92`.
  - Publish path: `DEPLOYING:8-10` documents committing `download/` and pushing.
  - Optional upload: `rake upload` calls `scp` through `Rakefile:94-97`.

## Environment Configuration

**Required env vars:**
- None required for default local execution with `rake` or `bin/koans walk`.

**Optional env vars:**
- `SIMPLE_KOAN_OUTPUT` - Plain completion output in `src/neo.rb:93-95`.
- `NO_COLOR` - Disable color output in `src/neo.rb:125-127`.
- `ANSI_COLOR` - Force or influence ANSI color output in `src/neo.rb:127-135`.
- `NEO_DISABLE_END` - Disable Neo `END` hook in `src/neo.rb:557-562`; used by `bin/koans:221-226` and `tests/neo_output_test.rb:3`.
- `KOANS_WATCH_INTERVAL` - Polling interval for `bin/koans watch` in `bin/koans:175-179`.
- `KOANS_NO_CLEAR` - Prevent screen clearing in `bin/koans:181-183`.
- `KOANS_PROGRESS_FILE` - Override progress-file location in `bin/koans:196-198`; useful in tests and isolated sessions.

**Secrets location:**
- Not stored in this repository.
- SSH credentials for `rake upload` must come from the developer/system SSH agent or SSH config outside the repository.
- GitHub Actions uses default platform credentials only; `.github/workflows/ci.yml` does not reference `secrets.*`.

## Webhooks & Callbacks

**Incoming:**
- None.
  - No web server, Rack app, Rails routes, Sinatra app, webhook endpoints, or HTTP listener detected.

**Outgoing:**
- None at runtime.
  - The koan runner does not call external APIs.
  - Build/deployment tooling may access RubyGems during dependency installation, GitHub during CI, Git remote endpoints during `git push`, and `linode:sites/onestepback.org/download` during `rake upload`.

---

*Integration audit: 2026-05-07*
