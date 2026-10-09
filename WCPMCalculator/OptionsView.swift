import SwiftUI
import SwiftData

struct OptionsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]
    @AppStorage("language") private var language = AppLanguage.english.rawValue

    @State private var showEditor = false
    @State private var editing: Profile?
    @State private var name = ""
    @State private var pendingDelete: Profile?

    var body: some View {
        NavigationStack {
            Form {
                Section("Language") {
                    Picker("Language", selection: $language) {
                        ForEach(AppLanguage.allCases) { Text($0.label).tag($0.rawValue) }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Profiles") {
                    ForEach(profiles) { profile in
                        Button(profile.name) { edit(profile) }
                            .foregroundStyle(.primary)
                            .swipeActions {
                                Button("Delete", role: .destructive) { pendingDelete = profile }
                            }
                    }
                    Button("Add profile", systemImage: "plus") { edit(nil) }
                }
            }
            .navigationTitle("Options")
            .alert(editing == nil ? "Add profile" : "Rename profile", isPresented: $showEditor) {
                TextField("Name", text: $name)
                Button("Save", action: save)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                Button("Cancel", role: .cancel) {}
            }
            .alert("Delete profile?", isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let p = pendingDelete { context.delete(p) }
                    pendingDelete = nil
                }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            } message: {
                Text("This also deletes its tests and results.")
            }
        }
    }

    private func edit(_ profile: Profile?) {
        editing = profile
        name = profile?.name ?? ""
        showEditor = true
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let editing { editing.name = trimmed } else { context.insert(Profile(name: trimmed)) }
    }
}
