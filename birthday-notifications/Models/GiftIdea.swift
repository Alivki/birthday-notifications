//
//  Giftidea.swift
//  final-birthday-notifications
//
//  Created by Iver Lindholm on 01/03/2026.
//

import Foundation
import SwiftData

@Model
final class GiftIdea {
    var title: String
    var notes: String
    var estimatedPrice: Double?
    var url: String?
    var isPurchased: Bool
    @Attribute(.externalStorage)
    var photoData: Data?

    var person: Person?

    var createdAt: Date

    init(
        title: String,
        notes: String = "",
        estimatedPrice: Double? = nil,
        url: String? = nil,
        isPurchased: Bool = false,
        photoData: Data? = nil,
        person: Person? = nil
    ) {
        self.title = title
        self.notes = notes
        self.estimatedPrice = estimatedPrice
        self.url = url
        self.isPurchased = isPurchased
        self.photoData = photoData
        self.person = person
        self.createdAt = .now
    }
}
