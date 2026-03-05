import SwiftData
import SwiftUI

struct GroupsTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PersonGroup.name) private var groups: [PersonGroup]
    @State private var showAddGroup = false
    @State private var newGroupName = ""
    @State private var newGroupColor: Color = .blue

    var body: some View {
        NavigationStack {
            List {
                ForEach(groups) { group in
                    NavigationLink(value: group.persistentModelID) {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(group.color)
                                .frame(width: 14, height: 14)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(group.name)
                                    .font(.body.weight(.medium))
                                Text("\(group.members.count) people")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        modelContext.delete(groups[index])
                    }
                }
            }
            .navigationTitle("Groups")
            .navigationDestination(for: PersistentIdentifier.self) { id in
                GroupDetailView(groupID: id)
            }
            .overlay {
                if groups.isEmpty {
                    ContentUnavailableView(
                        "No Groups Yet",
                        systemImage: "folder.badge.plus",
                        description: Text("Tap + to create a group")
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddGroup = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddGroup) {
                AddGroupSheet(
                    name: $newGroupName,
                    color: $newGroupColor
                ) {
                    let trimmed = newGroupName.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    let group = PersonGroup(name: trimmed, colorHex: newGroupColor.toHex())
                    modelContext.insert(group)
                    newGroupName = ""
                    newGroupColor = .blue
                    showAddGroup = false
                }
            }
        }
    }
}

// MARK: - Group Detail

struct GroupDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let groupID: PersistentIdentifier

    @State private var showEditSheet = false

    private var group: PersonGroup? {
        try? modelContext.model(for: groupID) as? PersonGroup
    }

    var body: some View {
        if let group {
            List {
                Section {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(group.color)
                            .frame(width: 20, height: 20)
                        Text(group.name)
                            .font(.title3.weight(.semibold))
                    }
                }

                Section("Members (\(group.members.count))") {
                    if group.members.isEmpty {
                        Text("No members yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(group.members) { person in
                            NavigationLink(value: person.persistentModelID) {
                                PersonRow(person: person)
                            }
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                group.members.remove(at: index)
                            }
                        }
                    }
                }
            }
            .navigationTitle(group.name)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: PersistentIdentifier.self) { id in
                PersonDetailView(personID: id)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") {
                        showEditSheet = true
                    }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                EditGroupSheet(group: group)
            }
        } else {
            ContentUnavailableView("Group Not Found", systemImage: "folder.badge.questionmark")
        }
    }
}

// MARK: - Add Group Sheet

struct AddGroupSheet: View {
    @Binding var name: String
    @Binding var color: Color
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Group name", text: $name)
                }

                Section {
                    ColorPicker("Color", selection: $color, supportsOpacity: false)
                }
            }
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave() }
                        .fontWeight(.semibold)
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .tint(.blue)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - Edit Group Sheet

struct EditGroupSheet: View {
    let group: PersonGroup
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var selectedColor: Color

    init(group: PersonGroup) {
        self.group = group
        _name = State(initialValue: group.name)
        _selectedColor = State(initialValue: Color(hex: group.colorHex))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Group name", text: $name)
                }

                Section {
                    ColorPicker("Color", selection: $selectedColor, supportsOpacity: false)
                }
            }
            .navigationTitle("Edit Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        group.name = name
                        group.colorHex = selectedColor.toHex()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .tint(.blue)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
