import SwiftData
import SwiftUI

struct GroupSelectionView: View {
    @Query(sort: \PersonGroup.name) private var allGroups: [PersonGroup]
    @Binding var selectedGroups: Set<PersistentIdentifier>
    @State private var showNewGroup = false
    @State private var newGroupName = ""
    @State private var newGroupColor: Color = .blue
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                Button {
                    selectedGroups.removeAll()
                    dismiss()
                } label: {
                    HStack {
                        Text("No Group")
                            .foregroundStyle(.black)
                        Spacer()
                        if selectedGroups.isEmpty {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }

            Section {
                ForEach(allGroups) { group in
                    Button {
                        toggle(group)
                        dismiss()
                    } label: {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(group.color)
                                .frame(width: 12, height: 12)
                            Text(group.name)
                                .foregroundStyle(.black)
                            Spacer()
                            if selectedGroups.contains(group.id) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Group")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showNewGroup = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showNewGroup) {
            AddGroupSheet(
                name: $newGroupName,
                color: $newGroupColor
            ) {
                let trimmed = newGroupName.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                let group = PersonGroup(name: trimmed, colorHex: newGroupColor.toHex())
                modelContext.insert(group)
                selectedGroups.insert(group.persistentModelID)
                newGroupName = ""
                newGroupColor = .blue
                showNewGroup = false
            }
        }
    }

    private func toggle(_ group: PersonGroup) {
        if selectedGroups.contains(group.id) {
            selectedGroups.remove(group.id)
        } else {
            selectedGroups.insert(group.id)
        }
    }
}
