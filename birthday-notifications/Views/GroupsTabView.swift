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
                    CardLink(value: group.persistentModelID) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(group.color.opacity(0.18))
                                    .frame(width: 48, height: 48)
                                Image(systemName: "folder.fill")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(group.color)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(group.name)
                                    .font(.system(.body).weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text("^[\(group.members.count) person](inflect: true)")
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.textSecondary)
                            }

                            Spacer()
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                                .fill(Theme.card)
                        )
                        .cardShadow()
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .onDelete { offsets in
                    for index in offsets {
                        modelContext.delete(groups[index])
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.surface)
            .navigationTitle("Groups")
            .navigationDestination(for: PersistentIdentifier.self) { id in
                if let _ = try? modelContext.model(for: id) as? Person {
                    PersonDetailView(personID: id)
                } else if let _ = try? modelContext.model(for: id) as? Event {
                    EventDetailView(eventID: id)
                } else {
                    GroupDetailView(groupID: id)
                }
            }
            .overlay {
                if groups.isEmpty {
                    ContentUnavailableView(
                        "No groups yet",
                        systemImage: "folder.badge.plus",
                        description: Text("Group people by family, friends, or anything else.")
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
                    HStack(alignment: .firstTextBaseline) {
                        Text("^[\(group.members.count) member](inflect: true)")
                            .font(.system(.title3).weight(.bold))
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 6)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                if group.members.isEmpty {
                    Section {
                        Text("No one in this group yet")
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.horizontal, 20)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                } else {
                    Section {
                        ForEach(group.members) { person in
                            CardLink(value: person.persistentModelID) {
                                PersonRow(person: person)
                            }
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                group.members.remove(at: index)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.surface)
            .navigationTitle(group.name)
            .navigationBarTitleDisplayMode(.inline)
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

// MARK: - Color swatch picker

struct GroupColorSwatchPicker: View {
    @Binding var selection: Color

    private var selectedHex: String { selection.toHex().uppercased() }

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 5)
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(groupColorOptions, id: \.hex) { option in
                let optionHex = option.hex.uppercased()
                let isSelected = selectedHex == optionHex
                Button {
                    selection = Color(hex: option.hex)
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(hex: option.hex))
                            .frame(width: 38, height: 38)
                        if isSelected {
                            Circle()
                                .stroke(Color(hex: option.hex), lineWidth: 2)
                                .frame(width: 48, height: 48)
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
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
                    GroupColorSwatchPicker(selection: $color)
                } header: {
                    Text("Color")
                }
            }
            .navigationTitle("New group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                SaveCancelToolbar(
                    saveDisabled: name.trimmingCharacters(in: .whitespaces).isEmpty,
                    onSave: onSave
                )
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
                    GroupColorSwatchPicker(selection: $selectedColor)
                } header: {
                    Text("Color")
                }
            }
            .navigationTitle("Edit group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                SaveCancelToolbar(
                    saveDisabled: name.trimmingCharacters(in: .whitespaces).isEmpty
                ) {
                    group.name = name
                    group.colorHex = selectedColor.toHex()
                    dismiss()
                }
            }
        }
    }
}
