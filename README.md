# WCPM Calculator

A native iOS app for measuring reading fluency in **words correct per minute (WCPM)**. Time a reader with a big on-screen stopwatch, record the wrong words, and keep every result per profile and per test so progress can be tracked over time.

Available in English and Portuguese (Portugal).

> **Status:** in development. Profiles, language switching, the WCPM calculation and the test timer are in place. The results screens are in place; polish remains. See [Roadmap](#roadmap).

## Features

- **Profiles** to keep results separate (for example one per reader).
- **Tests** per profile. Each test has a name, optional details and a word count.
- **Big start/stop timer** for running a test.
- **Repeat a test**: pick an existing test and run it again; each run is stored as a new result.
- **Results per run**: time, number of wrong words and WCPM.
- **Results view** to browse a profile's tests and their history, with a progress chart per test.
- **Options** to change the language and manage profiles.

## How WCPM is calculated

```
WCPM = (words in passage − wrong words) / minutes
```

For example, 100 words with 5 wrong in 90 seconds gives `95 / 1.5 ≈ 63.3`. Wrong words can never push the score below zero.

## How a test works

1. Choose a profile and a test (or create a new one: name, optional details, number of words).
2. Tap the large start button when the reader begins, and tap it again when they finish.
3. Enter the number of wrong words.
4. The result (time, wrong words, WCPM) is saved under that test.

## Requirements

- macOS with Xcode 26 or later
- iOS 17.0+ deployment target (iPhone, portrait)

No third-party packages are used.

## Build and run

Open `WCPMCalculator.xcodeproj` in Xcode, choose an iPhone simulator and press Run. Or from the command line:

```sh
xcodebuild test -project WCPMCalculator.xcodeproj -scheme WCPMCalculator \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO
```

To run on a physical device, set your own team under Signing & Capabilities. The bundle id is `com.algorithmcloud.WCPMCalculator`.

## Project structure

```
WCPMCalculator/
  WCPMCalculatorApp.swift   App entry and SwiftData container
  Models.swift              Profile, ReadingTest, TestResult, WCPM calculation
  ContentView.swift         Root tab view and language setting
  OptionsView.swift         Language and profile management
  ResultsView.swift         Tests list, history and progress chart
  TestView.swift            Test setup, stopwatch and result entry
  Localizable.xcstrings     English and Portuguese strings
WCPMCalculatorTests/
  WCPMTests.swift           Unit tests (Swift Testing)
WCPMCalculatorUITests/
  FlowUITests.swift         End-to-end smoke test
```

Data is stored locally on the device with SwiftData: a profile has many tests, and a test has many results. Deleting a profile or test deletes everything under it (the app asks for confirmation first).

## Localization

The app ships in English (`en`) and European Portuguese (`pt-PT`). Choose the language in **Options**; the choice applies immediately and is remembered. All strings live in `WCPMCalculator/Localizable.xcstrings`. To add a language, add it to the catalog and to `AppLanguage` in `ContentView.swift`.

## Roadmap

- [x] Project scaffold, data model, WCPM calculation and tests
- [x] Options: language switch and profile add / rename / delete
- [x] Test tab: setup form, stopwatch, wrong-words entry, save
- [x] Results tab: per-profile tests, history list, progress chart, delete
- [ ] Polish: complete Portuguese strings, Dynamic Type, dark mode
- [ ] Future: export results (CSV / share sheet), iCloud sync
