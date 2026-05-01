//
//  person.swift
//  final-birthday-notifications
//
//  Created by Iver Lindholm on 01/03/2026.
//

import Foundation
import SwiftData

@Model
final class Person {
    var firstName: String
    var lastName: String
    var notes: String
    var birthdayDay: Int
    var birthdayMonth: Int
    var birthdayYear: Int
    @Attribute(.externalStorage)
    var photoData: Data?

    var notifyOnDay: Bool
    var notifyOneWeekBefore: Bool

    @Relationship(deleteRule: .cascade, inverse: \GiftIdea.person)
    var giftIdeas: [GiftIdea]

    @Relationship(inverse: \PersonGroup.members)
    var groups: [PersonGroup]

    var createdAt: Date

    var fullName: String {
        [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
    }

    var nextBirthday: Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let thisYear = calendar.component(.year, from: today)

        var comps = DateComponents(year: thisYear, month: birthdayMonth, day: birthdayDay)
        if let candidate = calendar.date(from: comps), candidate >= today {
            return candidate
        }
        comps.year = thisYear + 1
        return calendar.date(from: comps) ?? today
    }

    var daysUntilBirthday: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return max(calendar.dateComponents([.day], from: today, to: nextBirthday).day ?? 0, 0)
    }

    var turnsAge: Int {
        let calendar = Calendar.current
        let nextYear = calendar.component(.year, from: nextBirthday)
        return nextYear - birthdayYear
    }

    var formattedBirthday: String {
        let date = Calendar.current.date(from: DateComponents(year: birthdayYear, month: birthdayMonth, day: birthdayDay)) ?? Date()
        return Self.dayMonthYearFormatter.string(from: date)
    }

    var nextBirthdayWeekdayAndDate: String {
        Self.weekdayDateFormatter.string(from: nextBirthday)
    }

    private static let dayMonthYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy"
        return f
    }()

    private static let weekdayDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f
    }()

    init(
        firstName: String,
        lastName: String = "",
        notes: String = "",
        birthdayDay: Int = 1,
        birthdayMonth: Int = 1,
        birthdayYear: Int = 2000,
        photoData: Data? = nil,
        notifyOnDay: Bool = true,
        notifyOneWeekBefore: Bool = true,
        giftIdeas: [GiftIdea] = [],
        groups: [PersonGroup] = []
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.notes = notes
        self.birthdayDay = birthdayDay
        self.birthdayMonth = birthdayMonth
        self.birthdayYear = birthdayYear
        self.photoData = photoData
        self.notifyOnDay = notifyOnDay
        self.notifyOneWeekBefore = notifyOneWeekBefore
        self.giftIdeas = giftIdeas
        self.groups = groups
        self.createdAt = .now
    }
}
