import SwiftUI
import SwiftData
import Charts

struct ResultsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]
    @State private var profileID: PersistentIdentifier?
    @State private var pendingDelete: ReadingTest?

    private var profile: Profile? {
        profiles.first { $0.persistentModelID == profileID } ?? profiles.first
    }

    var body: some View {
        NavigationStack {
            Group {
                if let profile {
                    list(for: profile)
                } else {
                    ContentUnavailableView("No profiles", systemImage: "person.crop.circle.badge.plus",
                                           description: Text("Add a profile in Options to start."))
                }
            }
            .navigationTitle("Results")
            .navigationDestination(for: ReadingTest.self) { TestDetailView(test: $0) }
            .alert("Delete test?", isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let t = pendingDelete { context.delete(t) }
                    pendingDelete = nil
                }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            } message: {
                Text("This also deletes its results.")
            }
        }
    }

    private func list(for profile: Profile) -> some View {
        List {
            Picker("Profile", selection: Binding(
                get: { profile.persistentModelID },
                set: { profileID = $0 }
            )) {
                ForEach(profiles) { Text($0.name).tag($0.persistentModelID) }
            }
            Section("Tests") {
                if profile.tests.isEmpty {
                    Text("No results yet").foregroundStyle(.secondary)
                }
                ForEach(profile.tests.sorted { $0.name < $1.name }) { test in
                    NavigationLink(value: test) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(test.name).font(.headline)
                                Text("\(test.results.count) results").font(.subheadline).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let last = test.results.max(by: { $0.date < $1.date }) {
                                Text(last.wcpm.oneDecimal).font(.title3.bold())
                            }
                        }
                    }
                    .swipeActions {
                        Button("Delete", role: .destructive) { pendingDelete = test }
                    }
                }
            }
        }
    }
}

struct TestDetailView: View {
    @Environment(\.modelContext) private var context
    let test: ReadingTest

    private var results: [TestResult] { test.results.sorted { $0.date > $1.date } }

    var body: some View {
        List {
            if !test.details.isEmpty {
                Text(test.details).foregroundStyle(.secondary)
            }
            Section("Progress") {
                Chart(results) {
                    LineMark(x: .value("Date", $0.date), y: .value("WCPM", $0.wcpm))
                    PointMark(x: .value("Date", $0.date), y: .value("WCPM", $0.wcpm))
                }
                .frame(height: 200)
            }
            Section("History") {
                ForEach(results) { r in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(r.date, format: .dateTime.day().month().year().hour().minute())
                            Text("\(r.duration.clock) · \(r.wrongWords) wrong")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(r.wcpm.oneDecimal).font(.title3.bold())
                    }
                }
                .onDelete { $0.forEach { context.delete(results[$0]) } }
            }
        }
        .navigationTitle(test.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
