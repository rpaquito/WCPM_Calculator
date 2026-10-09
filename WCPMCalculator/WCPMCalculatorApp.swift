import SwiftUI
import SwiftData

@main
struct WCPMCalculatorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Profile.self, ReadingTest.self, TestResult.self])
    }
}
