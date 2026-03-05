//
//  GroupViewModel.swift
//  final-birthday-notifications
//
//  Created by Iver Lindholm on 01/03/2026.
//

import Foundation
import SwiftData
import SwiftUI

@Observable
final class GroupViewModel {
    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func addGroup(name: String, colorHex: String = "007AFF") -> PersonGroup {
        let group = PersonGroup(name: name, colorHex: colorHex)
        modelContext.insert(group)
        return group
    }

    func deleteGroup(_ group: PersonGroup) {
        modelContext.delete(group)
    }

    func addMember(_ person: Person, to group: PersonGroup) {
        guard !group.members.contains(where: { $0.id == person.id }) else { return }
        group.members.append(person)
    }

    func removeMember(_ person: Person, from group: PersonGroup) {
        group.members.removeAll { $0.id == person.id }
    }
}
