import SwiftUI
import SwiftData

/// Everything needed to run one test. The `ReadingTest` is only created on save,
/// so abandoned runs leave no orphan tests behind.
struct RunConfig: Identifiable {
    let id = UUID()
    let profile: Profile
    let test: ReadingTest?
    let name: String
    let details: String
    let wordCount: Int
}

struct TestView: View {
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]
    @State private var profileID: PersistentIdentifier?
    @State private var selectedTest: ReadingTest?
    @State private var name = ""
    @State private var details = ""
    @State private var wordsText = ""
    @State private var run: RunConfig?

    private var profile: Profile? {
        profiles.first { $0.persistentModelID == profileID } ?? profiles.first
    }
    private var newWordCount: Int { Int(wordsText) ?? 0 }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }
    private var canStart: Bool {
        selectedTest != nil || (!trimmedName.isEmpty && newWordCount >= 1)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let profile {
                    form(for: profile)
                } else {
                    ContentUnavailableView("No profiles", systemImage: "person.crop.circle.badge.plus",
                                           description: Text("Add a profile in Options to start."))
                }
            }
            .navigationTitle("Test")
            .fullScreenCover(item: $run) { config in
                RunView(config: config) { selectedTest = $0 }
            }
        }
    }

    private func form(for profile: Profile) -> some View {
        Form {
            Picker("Profile", selection: Binding(
                get: { profile.persistentModelID },
                set: { profileID = $0; selectedTest = nil }
            )) {
                ForEach(profiles) { Text($0.name).tag($0.persistentModelID) }
            }
            Section("Test") {
                Picker("Test", selection: $selectedTest) {
                    Text("New test").tag(ReadingTest?.none)
                    ForEach(profile.tests.sorted { $0.name < $1.name }) { Text($0.name).tag(Optional($0)) }
                }
                if let selectedTest {
                    if !selectedTest.details.isEmpty { Text(selectedTest.details).foregroundStyle(.secondary) }
                    LabeledContent("Words", value: "\(selectedTest.wordCount)")
                } else {
                    TextField("Name", text: $name)
                    TextField("Details (optional)", text: $details)
                    TextField("Words", text: $wordsText).keyboardType(.numberPad)
                }
            }
            Button("Start test", action: start)
                .disabled(!canStart)
        }
    }

    private func start() {
        guard let profile else { return }
        run = RunConfig(
            profile: profile,
            test: selectedTest,
            name: selectedTest?.name ?? trimmedName,
            details: selectedTest?.details ?? details,
            wordCount: selectedTest?.wordCount ?? newWordCount
        )
        name = ""; details = ""; wordsText = ""
    }
}

struct RunView: View {
    let config: RunConfig
    let onSaved: (ReadingTest) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var start: Date?
    @State private var elapsed: TimeInterval = 0
    @State private var finished = false
    @State private var wrongText = ""

    private var wrongWords: Int? { Int(wrongText) }
    private var isValid: Bool {
        wrongWords.map { WCPM.isValid(wordCount: config.wordCount, wrongWords: $0, duration: elapsed) } ?? false
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                VStack {
                    Text(config.name).font(.title2.bold())
                    Text("\(config.wordCount) words").foregroundStyle(.secondary)
                }
                Spacer()
                TimelineView(.periodic(from: .now, by: 0.1)) { context in
                    let shown = start.map { context.date.timeIntervalSince($0) } ?? 0
                    Text(shown.clock)
                        .font(.system(size: 80, weight: .bold, design: .rounded).monospacedDigit())
                }
                Spacer()
                Button(action: toggle) {
                    Text(start == nil ? "Start" : "Stop")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 240, height: 240)
                        .background(start == nil ? Color.green : Color.red, in: Circle())
                }
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .sheet(isPresented: $finished) { entry }
        }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    private var entry: some View {
        NavigationStack {
            Form {
                LabeledContent("Time", value: elapsed.clock)
                LabeledContent("Words", value: "\(config.wordCount)")
                TextField("Wrong words", text: $wrongText).keyboardType(.numberPad)
                LabeledContent("WCPM", value: isValid
                    ? WCPM.compute(wordCount: config.wordCount, wrongWords: wrongWords ?? 0, duration: elapsed)
                        .formatted(.number.precision(.fractionLength(1)))
                    : "–")
                Button("Save", action: save).disabled(!isValid)
                Button("Discard", role: .destructive) { dismiss() }
            }
            .navigationTitle("Result")
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled()
    }

    private func toggle() {
        if let start {
            let t = Date.now.timeIntervalSince(start)
            guard t >= 1 else { return } // ignore accidental double tap
            elapsed = t
            finished = true
            UIApplication.shared.isIdleTimerDisabled = false
        } else {
            start = .now
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }

    private func save() {
        guard let wrongWords else { return }
        let test = config.test ?? {
            let t = ReadingTest(name: config.name, details: config.details,
                                wordCount: config.wordCount, profile: config.profile)
            context.insert(t)
            return t
        }()
        context.insert(TestResult(duration: elapsed, wordCount: config.wordCount,
                                  wrongWords: wrongWords, test: test))
        onSaved(test)
        dismiss()
    }
}
