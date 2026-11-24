# macro-spotlight-intents

A collection of Spotlight intents (macOS App Intents) that are triggered by [macro-pad](https://github.com/kgheacock/macro-pad), a custom 6-key macro keyboard.

See [`tasks/`](tasks/) for the task backlog.

## Getting started

You need a Mac with Xcode 26 or newer, Node 22.18 or newer, and a paid Apple
Developer Program membership (code signing is required for the intents to
reach Spotlight and Shortcuts).

1. Install XcodeGen: `brew install xcodegen`
2. Run `node scripts/bootstrap.ts`. It creates `Config/Signing.local.xcconfig`
   from the example, then generates `MacroSpotlightIntents.xcodeproj`.
3. Open `Config/Signing.local.xcconfig` and set:
   - `DEVELOPMENT_TEAM`: your Team ID, from <https://developer.apple.com/account> > Membership details.
   - `BUNDLE_ID_PREFIX`: a reverse-DNS prefix you own, for example `com.yourname`.
4. Run `node scripts/bootstrap.ts` again so the project picks up the values, then
   `open MacroSpotlightIntents.xcodeproj`.
5. Build and test from the command line. `xcodebuild` needs full Xcode selected:
   run `sudo xcode-select -s /Applications/Xcode.app`, or prefix the commands with
   `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`. The first build
   needs `-allowProvisioningUpdates` so Xcode can create your Apple Development
   certificate and profile (you must be signed in under Xcode > Settings > Accounts).
   ```bash
   xcodebuild -scheme MacroSpotlightIntents -configuration Debug -allowProvisioningUpdates build
   xcodebuild -scheme MacroSpotlightIntents test
   ```
6. To try the intent, copy the built app to `/Applications` and launch it once.
   "Ping" then appears in Spotlight and in the Shortcuts app.

`Config/Signing.local.xcconfig` and the generated `.xcodeproj` are git-ignored.
Your Team ID never goes into git. Change project settings in `project.yml` or
the xcconfig files, not in the Xcode UI: the next generate throws UI changes away.

## Layout

```
project.yml                  XcodeGen spec
Config/                      xcconfig files (signing identity stays in the git-ignored local file)
Sources/MacroSpotlightIntents/
  App/                       @main menu bar app
  Intents/                   one file per AppIntent
  Shortcuts/                 AppShortcutsProvider
Tests/                       unit tests
scripts/bootstrap.ts         first-time setup
tasks/                       Task specs (see tasks/README.md)
```
