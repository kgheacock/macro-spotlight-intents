---
id: "0002"
title: "Add os.Logger logging to the app and every intent"
status: "ongoing"
created: "2026-11-23"
updated: "2026-11-23"
owner: "kgheacock"
issue: null
issue_url: null
pr: null
branch: "0002-add-logging-to-app-and-intents"
related: ["0001"]
tags: ["logging", "debugging"]
---

# 0002 — Add os.Logger logging to the app and every intent

## Problem

The app writes no log lines. When an intent runs from Spotlight or Shortcuts
and nothing happens, there is no way to tell if `perform()` ran, failed, or
never started. This happened on 2026-11-23: `PingIntent` showed in Spotlight and
Shortcuts, but running it showed no dialog. The developer has nothing to debug with.

## Goals

- One `log` command shows if an intent started, finished, or failed, and how long it took.
- Every intent logs in the same format.

## Non-goals

- Fix the missing `PingIntent` dialog. Logging finds the cause. A separate task fixes it.
- Send logs off the machine, or add crash reporting.

## Approaches considered

Three approaches follow. Each one solves the problem in a different way.

### Approach A — Direct `os.Logger` calls in each intent

Each intent creates a `Logger` and writes its own lines by hand.

- Good, because it adds no new types. Each intent needs about three lines.
- Good, because Console and `log stream` work with it at once.
- Bad, because a new intent that forgets the lines leaves no trace when it fails.
- Bad, because the wording drifts between intents, so one `log` predicate cannot match them all.

### Approach B — `AppLog` loggers and one `IntentLog.run` helper around each `perform()`

`IntentLog.run(name) { ... }` writes the start line, the finish line with the
duration, and the failure line. It then rethrows the error.

- Good, because every intent logs start, finish, duration, and failure in one format.
- Good, because it still uses `os.Logger`. It adds no dependency.
- Bad, because the compiler does not force an intent to call the helper.
- Bad, because every `perform()` gets one extra level of nesting.

### Approach C — Log to a file in the app container with `swift-log`

Add the `swift-log` package and a file handler that writes lines to the sandbox container.

- Good, because lines stay on disk and the developer can attach the file to a report.
- Good, because it does not depend on the retention rules of the unified log.
- Bad, because it adds a package and a file handler with rotation to maintain.
- Bad, because every intent run writes to disk, and the file sits in a container path that is hard to find.

## Decision

Chosen: **Approach B — `AppLog` loggers and one `IntentLog.run` helper**.

The goal is to learn from one command if `perform()` ran. Approach B gives the
same format for every intent at the lowest cost. The decision accepts that the
helper is a convention. A review must check that each new intent calls it.

## Design

`AppLog` holds two `Logger` values. The subsystem is `Bundle.main.bundleIdentifier`,
so no identity is in the source. The categories are `app` and `intents`.

`IntentLog.run` writes these lines:

- `<name> started` at `.notice` level, so `log show` finds it after the event.
- `<name> finished in <n> ms` at `.notice` level.
- `<name> failed after <n> ms: <error type>` at `.error` level.

The name, the duration, and the error type are public. The error text is private,
because a future intent can put user data in it.

Files to change:

- `Sources/MacroSpotlightIntents/Logging/AppLog.swift` — new, the two loggers
- `Sources/MacroSpotlightIntents/Logging/IntentLog.swift` — new, the helper
- `Sources/MacroSpotlightIntents/Intents/PingIntent.swift` — wrap `perform()`
- `Sources/MacroSpotlightIntents/App/MacroSpotlightIntentsApp.swift` — log one launch line
- `Tests/MacroSpotlightIntentsTests/IntentLogTests.swift` — new
- `README.md` — add a "Debugging" section

## Definition of done

An outside reviewer verifies each item without help from the implementer. Each
item names its proof. The task moves to `complete/` only when every box is
ticked.

- [ ] **DoD-1** — Running Ping from Shortcuts writes `PingIntent started` and
  `PingIntent finished in <n> ms`. **Proof:** run
  `log stream --level info --predicate 'subsystem == "<prefix>.MacroSpotlightIntents"'`
  while you run Ping, where `<prefix>` is `BUNDLE_ID_PREFIX` from `Config/Signing.local.xcconfig`
- [ ] **DoD-2** — The same two lines appear when Ping runs from Spotlight.
  **Proof:** the same command, with Ping started from Spotlight
- [ ] **DoD-3** — After the run, the lines are still readable. **Proof:**
  `log show --last 5m --predicate 'subsystem == "<prefix>.MacroSpotlightIntents"'` prints both lines
- [ ] **DoD-4** — Launching the app writes one `app launched version=<v> build=<b>` line.
  **Proof:** `log show --last 1m` with the same predicate, after you launch the app
- [ ] **DoD-5** — When the body throws, `IntentLog.run` still throws the same
  error to the caller. **Proof:** `xcodebuild test -scheme MacroSpotlightIntents`
  runs `IntentLogTests.rethrowsBodyError` and it passes. Then run
  `log show --last 1m --predicate 'subsystem == "<prefix>.MacroSpotlightIntents" AND messageType == error'`. It prints one `failed after` line
- [ ] **DoD-6** — `IntentLog.run` returns the value of its body. **Proof:**
  `IntentLogTests.returnsBodyValue` passes
- [ ] **DoD-7** — The source has no ad hoc logging. **Proof:**
  `grep -rnE 'print\(|NSLog\(' Sources` prints nothing
- [ ] **DoD-8** — `README.md` records the debug commands. **Proof:** `README.md`, section "Debugging"
- [ ] **DoD-9** — The PR in the `pr` field links to this spec. **Proof:** PR body

## Risks

- A future intent skips the helper → DoD-7 and review catch ad hoc logging, but not a missing call. Accepted by the decision.
- `.notice` lines fill the log store → each run writes two short lines. This is small for a macro pad.

## Open questions

- [ ] Do the logs show why the `PingIntent` dialog is missing? — the implementer, after DoD-1

## Notes

Task `0001` records the missing dialog in its Definition of done.
