//
//  PersonViewModel 2.swift
//  final-birthday-notifications
//
//  Created by Iver Lindholm on 01/03/2026.
//


import Foundation
import SwiftData
import SwiftUI

@Observable
final class PersonViewModel {
    private var modelContext: ModelContext

    var searchText = ""

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - People

    func addPerson(firstName: String, lastName: String = "", notes: String = "") -> Person {
        let person = Person(firstName: firstName, lastName: lastName, notes: notes)
        modelContext.insert(person)
        return person
    }

    func deletePerson(_ person: Person) {
        modelContext.delete(person)
    }
    
    // MARK: - Gift Ideas

    func addGiftIdea(
        to person: Person,
        title: String,
        notes: String = "",
        estimatedPrice: Double? = nil,
        url: String? = nil
    ) {
        let gift = GiftIdea(
            title: title,
            notes: notes,
            estimatedPrice: estimatedPrice,
            url: url,
            person: person
        )
        person.giftIdeas.append(gift)
    }

    func deleteGiftIdea(_ gift: GiftIdea, from person: Person) {
        person.giftIdeas.removeAll { $0.id == gift.id }
        modelContext.delete(gift)
    }

    func toggleGiftPurchased(_ gift: GiftIdea) {
        gift.isPurchased.toggle()
    }
}
