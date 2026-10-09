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
# Build + run unit and UI tests (simulator, no code signing; UI test takes ~20s)
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
  ResultsView.swift         Results tab: tests list per profile, TestDetailView (chart + history)
  TestView.swift            Test tab: setup form, RunConfig, RunView (stopwatch + result entry)
  Localizable.xcstrings     String catalog (en, pt-PT)
WCPMCalculatorTests/
  WCPMTests.swift           Swift Testing unit tests for WCPM math and validation
WCPMCalculatorUITests/
  FlowUITests.swift         XCUITest smoke test: add profile, run test, save result, view and delete it in Results
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
- `SWIFT_EMIT_LOC_STRINGS = YES` is set on the app target. To audit the catalog after adding views, build, then compare keys in `build/**/*.stringsdata` against `Localizable.xcstrings` (the build does not edit the catalog itself).
- Language names (`English`, `Português`) are shown untranslated on purpose.
- Every new user-facing string needs an entry in `Localizable.xcstrings` with both `en` and `pt-PT` values.
- Persisted state goes through SwiftData. Per-device preferences (language, active profile) go in `@AppStorage`.
- Timer logic must use wall/monotonic clock deltas, not tick counting, so it survives backgrounding.
- Keep tests small and runnable; add or extend a Swift Testing case for any new calculation or validation logic.

## Xcode project file

The shared scheme in `xcshareddata/xcschemes` lists both test targets so `xcodebuild test` runs unit and UI tests; keep it in sync if targets change.

`WCPMCalculator.xcodeproj/project.pbxproj` was written by hand using file-system synchronized groups (`PBXFileSystemSynchronizedRootGroup`, objectVersion 77). Consequences:

- New `.swift` files and resources placed under `WCPMCalculator/` or `WCPMCalculatorTests/` are picked up automatically. Do not edit `project.pbxproj` to add files.
- Edit `project.pbxproj` only for build settings or targets. Validate with `plutil -lint` and by running `xcodebuild -list`.
- `Info.plist` is generated (`GENERATE_INFOPLIST_FILE = YES`); add keys via `INFOPLIST_KEY_*` build settings.

## Status and roadmap

1. Done: scaffold, models, WCPM function, unit tests.
2. Done: tab shell, Options tab, profile CRUD, language switch.
3. Done: Test tab. A `ReadingTest` is created only when a run is saved (`RunConfig` carries the pending data), so abandoned runs leave nothing behind. Stop is ignored in the first second. The screen stays awake while running. `FlowUITests` covers the happy path; the Portuguese UI and the chart-feeding data are not covered.
4. Done: Results tab. Profile picker, tests list (latest WCPM, result count), per-test Swift Charts line chart and history; swipe deletes a result (no confirmation) or a test (confirmation). Data is covered by the UI smoke test; chart appearance is not checked.
5. Done: Polish (pt-PT screens, dark mode and the largest Dynamic Type size checked via screenshots). Remaining ideas, not started: remaining pt-PT strings, Dynamic Type, dark mode.

Future, explicitly out of scope for now: CSV / share export, iCloud sync.
