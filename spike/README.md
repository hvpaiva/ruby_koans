# spike/

One-off Phase-1 spikes. Files in this directory are **scaffolding** and are
deleted via `git rm` once their question is answered — see CONTEXT.md D-12.

Current spike: **WATCH-05** — does `listen 3.10` fire events on Ruby 4.0.3?

Run it locally:

```sh
bundle exec ruby spike/listen_check.rb
echo $?  # 0 = pass, 1 = fail
```

The companion GHA workflow `.github/workflows/spike-listen.yml` runs the same
script on `[ubuntu-latest, macos-latest] × ruby-4.0.3`. The verdict is recorded
in `.planning/phases/01-walking-skeleton/01-02-LISTEN-SPIKE-RESULT.md`.

When the spike closes (verdict recorded; Phase 2 plan acted on it), this entire
`spike/` directory is removed in a single commit.
