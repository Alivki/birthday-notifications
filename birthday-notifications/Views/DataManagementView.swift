import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var people: [Person]
    @Query private var events: [Event]
    @Query private var groups: [PersonGroup]

    @State private var showExportShare = false
    @State private var exportFileURL: URL?
    @State private var showImportPicker = false
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var showImportConfirm = false
    @State private var pendingImportURL: URL?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Label("People", systemImage: "person.2.fill")
                        Spacer()
                        Text("\(people.count)")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Label("Events", systemImage: "calendar")
                        Spacer()
                        Text("\(events.count)")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Label("Groups", systemImage: "folder.fill")
                        Spacer()
                        Text("\(groups.count)")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Your data")
                }

                Section {
                    Button {
                        exportData()
                    } label: {
                        Label("Export backup", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        showImportPicker = true
                    } label: {
                        Label("Import backup", systemImage: "square.and.arrow.down")
                    }
                } header: {
                    Text("Backup")
                } footer: {
                    Text("Export saves everything — people, events, groups, and photos — to a single JSON file. Import merges that file into your current data; nothing existing is removed.")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .sheet(isPresented: $showExportShare) {
                if let url = exportFileURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        pendingImportURL = url
                        showImportConfirm = true
                    }
                case .failure:
                    alertMessage = "Could not read the selected file."
                    showAlert = true
                }
            }
            .alert("Import backup?", isPresented: $showImportConfirm) {
                Button("Import") {
                    if let url = pendingImportURL {
                        importData(from: url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("People, events, and groups from this file will be added to what you already have. Nothing will be removed.")
            }
            .alert("Import", isPresented: $showAlert) {
                Button("OK") {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func exportData() {
        guard let data = BackupManager.exportData(people: people, events: events, groups: groups) else {
            alertMessage = "Failed to create backup."
            showAlert = true
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: Date())
        let filename = "birthday-backup-\(dateStr).json"

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: tempURL)
            exportFileURL = tempURL
            showExportShare = true
        } catch {
            alertMessage = "Failed to save backup file."
            showAlert = true
        }
    }

    private func importData(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            alertMessage = "Could not access the selected file."
            showAlert = true
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let data = try Data(contentsOf: url)
            let result = try BackupManager.importData(from: data, into: modelContext)
            alertMessage = "Imported \(result.people) people, \(result.events) events, and \(result.groups) new groups."
            showAlert = true
        } catch {
            alertMessage = "Failed to import: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
