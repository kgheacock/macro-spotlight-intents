---
id: 0001
title: Initial project setup with personal code signing
status: "ongoing"
created: 2026-11-23
updated: 2026-11-23
issue: none
pr: https://github.com/kgheacock/macro-spotlight-intents/pull/2
branch: "0001-initial-project-setup"
owner: kgheacock
---

# 0001 · Initial project setup with personal code signing

## Problem

The repo holds only task specs. There is no app, so there is nowhere to put an
App Intent and nothing Spotlight can index.

App Intents only reach Spotlight (and Shortcuts, which macro-pad uses to fire
them) when they ship inside a signed `.app` bundle that the system has
registered. So the first intent needs three things in place:

1. An Xcode app target that builds a macOS app holding the intents.
2. Code signing with Keith's personal Apple Developer identity, so the app
   launches without Gatekeeper prompts and the system registers its intents.
3. A way to keep that identity out of git. The repo is public. The Team ID,
   the bundle ID prefix, and any App Store Connect API key must never be
   committed.

Point 3 is the hard constraint. Xcode writes `DEVELOPMENT_TEAM` straight into
`project.pbxproj` the moment someone picks a team in the Signing & Capabilities
tab, so the default workflow leaks it.

## Approaches

### A. Committed `.xcodeproj`, team picked in the Xcode UI

Create the project in Xcode, tick "Automatically manage signing", pick the
personal team, commit the `.xcodeproj`.

- Pro: Zero extra tools. The path every Apple tutorial takes.
- Con: The Team ID lands in `project.pbxproj` and gets committed. A scrub
  needs a pre-commit hook or manual care on every commit.
- Con: `project.pbxproj` diffs are large and hard to review. Each new intent
  file adds UUID noise.

### B. XcodeGen spec plus a git-ignored signing `.xcconfig` (automatic signing)

Commit `project.yml` (XcodeGen) and a committed `Config/Signing.xcconfig` that
does `#include? "Signing.local.xcconfig"`. The local file holds
`DEVELOPMENT_TEAM` and `BUNDLE_ID_PREFIX`, is git-ignored, and is created from
a committed `Signing.local.xcconfig.example`. The `.xcodeproj` is generated and
git-ignored. Xcode's automatic signing does the rest.

- Pro: No identity in git, by construction rather than by discipline.
- Pro: `project.yml` is short and reviewable. Adding an intent file needs no
  project edit, because XcodeGen globs the source folder.
- Pro: The same xcconfig works for `xcodebuild` on the command line.
- Con: Adds a tool dependency (`brew install xcodegen`) and a
  `xcodegen generate` step after each clone or `project.yml` change.
- Con: Signing settings made in the Xcode UI get thrown away on the next
  generate. All changes go through `project.yml` or the xcconfig.

### C. Manual signing with exported certificates (fastlane match or similar)

Export the Developer ID / Apple Development certificate and provisioning
profile, store them encrypted (a private repo or a secrets store), and set
manual signing in the project.

- Pro: Fully reproducible on any machine or CI runner.
- Pro: Needed anyway if the app is ever notarized for distribution.
- Con: Heavy for one developer on one Mac. Adds a secrets store, a passphrase,
  and certificate rotation to look after.
- Con: Private keys leave the login keychain, which widens the attack surface.

## Decision

**B. XcodeGen plus a git-ignored signing xcconfig, with automatic signing.**

Signing identity lives in exactly two places, neither in git:

| What | Where | Committed? |
|---|---|---|
| Team ID (`DEVELOPMENT_TEAM`) | `Config/Signing.local.xcconfig` | No (git-ignored) |
| Bundle ID prefix (`BUNDLE_ID_PREFIX`) | `Config/Signing.local.xcconfig` | No (git-ignored) |
| Signing certificate and private key | macOS login keychain, managed by Xcode | No |
| App Store Connect API key (optional, headless builds only) | `~/.appstoreconnect/AuthKey_<KEY_ID>.p8`, path and IDs in env vars `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_PATH` | No |
| Placeholder values | `Config/Signing.local.xcconfig.example` | Yes |

The API key row is optional. It is only needed for `xcodebuild
-allowProvisioningUpdates` to create or refresh profiles without the Xcode UI
signed in. Plain local builds work with the Xcode account alone.

**Cost:** one more tool (`xcodegen`) and one more step after cloning. Signing
changes made in the Xcode UI do not stick. A move to CI later still needs
approach C's certificate export, so B defers that work rather than removing it.

## Prerequisite: paid Apple Developer Program

Keith chose a paid Apple Developer Program membership (decided 2026-11-23)
over a free personal team. Profiles from a free team expire after 7 days, and
a free team cannot create App Store Connect API keys or Developer ID
certificates. Enroll at <https://developer.apple.com/programs/enroll/> before
work starts. Approval can take a day or more.

Once enrolled, the Team ID is on the Membership details page at
<https://developer.apple.com/account>. It goes only in
`Config/Signing.local.xcconfig`.

## Scope

In scope:

- Folder layout:
  ```
  project.yml                         XcodeGen spec (committed)
  Config/
    Base.xcconfig                     deployment target, Swift version
    Signing.xcconfig                  includes Signing.local.xcconfig if present
    Signing.local.xcconfig.example    placeholders, committed
  Sources/MacroSpotlightIntents/
    App/                              @main SwiftUI app, minimal window or menu bar
    Intents/                          one file per AppIntent
    Shortcuts/                        AppShortcutsProvider
  Tests/MacroSpotlightIntentsTests/
  scripts/
    bootstrap.ts                      checks xcodegen, copies .example if missing, runs generate
  ```
- One macOS app target, deployment target macOS 26, Swift 6, App Sandbox on,
  Hardened Runtime on.
- One placeholder intent (`PingIntent`, returns a dialog "macro-spotlight-intents
  is working") registered in an `AppShortcutsProvider`, so registration can be
  proven end to end.
- A unit-test target that builds and runs one test of `PingIntent.perform()`.
- `.gitignore` additions: `*.xcodeproj/`, `Config/Signing.local.xcconfig`,
  `*.p8`, `*.p12`, `*.mobileprovision`, `*.provisionprofile`.
- A "Getting started" section in the root `README.md`: install xcodegen, run
  `scripts/bootstrap.ts`, fill in the local xcconfig, open the project.

Out of scope:

- Real intents beyond `PingIntent` (separate tasks).
- macro-pad wiring.
- Notarization, distribution, CI.

## Definition of done

A reviewer who did not write the change ticks each box.

- [x] On a fresh clone, `scripts/bootstrap.ts` produces
      `MacroSpotlightIntents.xcodeproj` with no errors.
- [ ] With `TEAM_ID` and `PREFIX` set to Keith's real values in the shell,
      `git log --all -p | grep -nE "$TEAM_ID|$PREFIX"` prints nothing. The only
      `DEVELOPMENT_TEAM` value in git is the placeholder in the `.example` file.
      Not confirmed: the implementer does not have Keith's real values. Only
      the placeholder `XXXXXXXXXX` / `com.example` are in git.
- [x] `git check-ignore Config/Signing.local.xcconfig MacroSpotlightIntents.xcodeproj`
      prints both paths.
- [ ] With `Signing.local.xcconfig` filled in, `xcodebuild -scheme
      MacroSpotlightIntents -configuration Debug build` succeeds from the
      command line.
      Not confirmed: the machine has only Command Line Tools (no Xcode), so
      `xcodebuild` cannot run. App sources pass `swiftc -typecheck` on the
      macOS 26 SDK.
- [ ] The Team ID in `Signing.local.xcconfig` belongs to the paid Developer
      Program membership, not a "Personal Team" (Xcode > Settings > Accounts
      shows the team without the "(Personal Team)" suffix).
      Not confirmed: needs Keith's Xcode account.
- [ ] `codesign -dv --verbose=2` on the built `.app` shows
      `TeamIdentifier=` set to Keith's Team ID (not `not set`) and an
      `Apple Development` authority.
      Not confirmed: no built app, and `security find-identity` shows 0
      signing identities on this machine.
- [ ] `codesign --verify --deep --strict` on the built `.app` exits 0.
      Not confirmed: no built app.
- [ ] `xcodebuild test -scheme MacroSpotlightIntents` passes.
      Not confirmed: no Xcode. The `Testing` module is also missing from
      Command Line Tools, so the test file was not type-checked.
- [ ] After copying the app to `/Applications` and launching it once, "Ping"
      appears in Spotlight and in the Shortcuts app, and running it shows the
      dialog.
      Not confirmed: needs a signed build.
- [ ] Deleting `Config/Signing.local.xcconfig` makes the build fail with a
      signing error that names the missing team, not a silent ad-hoc build.
      Not confirmed: needs `xcodebuild`. Design: `Config/Signing.xcconfig`
      leaves `DEVELOPMENT_TEAM` empty when the local file is missing.
- [ ] The root `README.md` "Getting started" steps work as written on a clean
      clone.
      Not confirmed: steps 1–4 ran on a fresh clone; steps 5–6 need Xcode.
- [x] No `.p8`, `.p12`, or provisioning profile is tracked:
      `git ls-files | grep -E '\.(p8|p12|mobileprovision|provisionprofile)$'`
      prints nothing.

## Open questions

- "Personal app token" is read here as Keith's personal Apple Developer
  signing identity (Team ID with automatic signing), plus an optional App Store
  Connect API key for headless builds. If it means something else, such as a
  token the intents use to call an outside service, add a section on where that
  token lives (keychain item read at runtime) before work starts.
