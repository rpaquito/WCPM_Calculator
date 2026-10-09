import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case portuguese = "pt-PT"

    var id: String { rawValue }
    var label: String { self == .english ? "English" : "Português" }
}

struct ContentView: View {
    @AppStorage("language") private var language = AppLanguage.english.rawValue

    var body: some View {
        TabView {
            TestView().tabItem { Label("Test", systemImage: "stopwatch") }
            ResultsView().tabItem { Label("Results", systemImage: "chart.line.uptrend.xyaxis") }
            OptionsView().tabItem { Label("Options", systemImage: "gearshape") }
        }
        .environment(\.locale, Locale(identifier: language))
    }
}
