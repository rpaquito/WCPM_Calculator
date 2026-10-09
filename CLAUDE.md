# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project

Native iOS app that calculates reading fluency as WCPM (words correct per minute). A reader reads a passage while a stopwatch runs. The user then enters the number of wrong words and the app stores the result under a profile and a named test.

- Bundle id: `com.algorithmcloud.WCPMCalculator` (tests: `com.algorithmcloud.WCPMCalculatorTests`)
- SwiftUI + SwiftData, iOS 17+, iPhone only, portrait only
- Languages: English (`en`, development language) and European Portuguese (`pt-PT`)
- No third-party dependencies. Keep it that way unless there is a strong reason.

## Commands

Run from the repository root. Xcode 26 is installed; there is no `xcodegen`.

```sh
# Build + run unit tests (simulator, no code signing)
xcodebuild test -project WCPMCalculator.xcodeproj -scheme WCPMCalculator \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO

# Build only
xcodebuild build -project WCPMCalculator.xcodeproj -scheme WCPMCalculator \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO

# Install and launch in an already-booted simulator
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/WCPMCalculator.app
xcrun simctl launch booted com.algorithmcloud.WCPMCalculator
xcrun simctl io booted screenshot out.png
```

The first test run prints many `CoreData: error: Failed to stat path ... default.store` lines. This is the SwiftData store directory being created on first launch and is harmless. Filter output with `grep -E "error:|^\*\* |Test run"` to see real failures.

`build/` is git-ignored.

## Architecture

```
WCPMCalculator/
  WCPMCalculatorApp.swift   App entry; attaches the SwiftData model container
  Models.swift              Profile, ReadingTest, TestResult, WCPM calculation
  ContentView.swift         AppLanguage enum + root TabView (Test / Results / Options)
  OptionsView.swift         Language picker and profile add / rename / delete
  Localizable.xcstrings     String catalog (en, pt-PT)
WCPMCalculatorTests/
  WCPMTests.swift           Swift Testing unit tests for WCPM math and validation
```

### Data model

`Profile` 1—* `ReadingTest` 1—* `TestResult`, all with cascade delete (deleting a profile deletes its tests and results; the UI confirms first).

- `ReadingTest`: name, details (optional), wordCount. Belongs to one profile. Redoing a test creates another `TestResult` under the same `ReadingTest`.
- `TestResult`: date, duration (seconds), wordCount, wrongWords, wcpm. `wordCount` is a snapshot copied from the test at run time so later edits to the test do not alter history. `wcpm` is stored, computed once in `init` via `WCPM.compute`.
- `WCPM.compute` = `max(0, wordCount - wrongWords) / (duration / 60)`; returns 0 when duration <= 0.
- `WCPM.isValid` is the single source of truth for input validation: duration > 0, wordCount >= 1, 0 <= wrongWords <= wordCount. UI must use it rather than re-implementing the rules.

### Naming gotchas

- Do not name a model `Test`: it collides with the `Test` type from Swift Testing. Use `ReadingTest`.
- Do not name a model `Result`: it shadows `Swift.Result`. Use `TestResult`.

## Conventions

- Tabs use `.tabItem`, not the `Tab` type (`Tab` requires iOS 18; deployment target is 17).
- Language is chosen in-app and stored in `@AppStorage("language")` (`"en"` or `"pt-PT"`). `ContentView` applies it with `.environment(\.locale, ...)`. Views use plain `Text("Key")` / `Button("Key")` so the catalog resolves them. For strings built outside a view, use `String(localized:locale:)` with the same locale.
- Language names (`English`, `Português`) are shown untranslated on purpose.
- Every new user-facing string needs an entry in `Localizable.xcstrings` with both `en` and `pt-PT` values.
- Persisted state goes through SwiftData. Per-device preferences (language, active profile) go in `@AppStorage`.
- Timer logic must use wall/monotonic clock deltas, not tick counting, so it survives backgrounding.
- Keep tests small and runnable; add or extend a Swift Testing case for any new calculation or validation logic.

## Xcode project file

`WCPMCalculator.xcodeproj/project.pbxproj` was written by hand using file-system synchronized groups (`PBXFileSystemSynchronizedRootGroup`, objectVersion 77). Consequences:

- New `.swift` files and resources placed under `WCPMCalculator/` or `WCPMCalculatorTests/` are picked up automatically. Do not edit `project.pbxproj` to add files.
- Edit `project.pbxproj` only for build settings or targets. Validate with `plutil -lint` and by running `xcodebuild -list`.
- `Info.plist` is generated (`GENERATE_INFOPLIST_FILE = YES`); add keys via `INFOPLIST_KEY_*` build settings.

## Status and roadmap

1. Done: scaffold, models, WCPM function, unit tests.
2. Done (build verified, UI not yet exercised by hand): tab shell, Options tab, profile CRUD, language switch.
3. Next: Test tab. Profile picker, new or existing test, setup form (name, optional details, word count), large start/stop button with `mm:ss` display, wrong-words entry sheet, save. Block stop in the first second. Keep the screen awake while running.
4. Results tab: profile picker, tests list, per-test detail with a Swift Charts WCPM-over-time chart and results list (date, time, wrong words, WCPM), swipe to delete.
5. Polish: remaining pt-PT strings, Dynamic Type, dark mode.

Future, explicitly out of scope for now: CSV / share export, iCloud sync.
