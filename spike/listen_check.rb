#!/usr/bin/env ruby
# frozen_string_literal: true

# spike/listen_check.rb — WATCH-05 Phase-1 spike.
#
# Question: does `listen 3.10` fire events on Ruby 4.0.3?
# Method:   create a tmpdir, start a Listen.to(...) listener, write a file inside it,
#           wait up to 1.0s for the listener block to fire.
# Verdict:  exit 0 = listen works on this platform/Ruby. exit 1 = does not.
#
# Per CONTEXT.md D-12, this script is one-off scaffolding and is git-removed once
# WATCH-05 closes (either both GHA legs green AND local Linux green => remove,
# or activate the --polling fallback for the affected platform in Phase 2 => remove).

require "listen"
require "tmpdir"
require "fileutils"

EVENT_BUDGET_SECONDS = 1.0
LATENCY_SECONDS      = 0.2
WIRE_UP_DELAY        = 0.3
POLL_INTERVAL        = 0.05

Dir.mktmpdir("listen_spike") do |tmp|
  received = false

  listener = Listen.to(tmp, latency: LATENCY_SECONDS) do |modified, added, removed|
    # Listen invokes this block from its own thread. We only need a flag flip;
    # actual file analysis is irrelevant for the spike.
    received = true
  end

  listener.start
  sleep WIRE_UP_DELAY  # let inotify/fsevent register the watch before we write

  target = File.join(tmp, "x.rb")
  File.write(target, "# spike write\n")

  deadline = Time.now + EVENT_BUDGET_SECONDS
  sleep POLL_INTERVAL until received || Time.now > deadline

  listener.stop

  if received
    warn "[spike] listen fired an event within budget (latency=#{LATENCY_SECONDS}s, budget=#{EVENT_BUDGET_SECONDS}s) on #{RUBY_PLATFORM} / Ruby #{RUBY_VERSION}"
    exit 0
  else
    warn "[spike] listen did NOT fire an event within #{EVENT_BUDGET_SECONDS}s on #{RUBY_PLATFORM} / Ruby #{RUBY_VERSION}"
    exit 1
  end
end
