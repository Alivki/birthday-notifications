import Foundation
import SwiftData
import SwiftUI

@Model
final class Event {
    var name: String
    var notes: String
    var eventDay: Int
    var eventMonth: Int
    var eventYear: Int?
    var iconName: String
    var colorHex: String
    var createdAt: Date

    var color: Color {
        Color(hex: colorHex)
    }

    var nextOccurrence: Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let thisYear = calendar.component(.year, from: today)

        var comps = DateComponents(year: thisYear, month: eventMonth, day: eventDay)
        if let candidate = calendar.date(from: comps), candidate >= today {
            return candidate
        }
        comps.year = thisYear + 1
        return calendar.date(from: comps) ?? today
    }

    var daysUntilEvent: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return max(calendar.dateComponents([.day], from: today, to: nextOccurrence).day ?? 0, 0)
    }

    var turnsYears: Int? {
        guard let year = eventYear else { return nil }
        let calendar = Calendar.current
        let nextYear = calendar.component(.year, from: nextOccurrence)
        return nextYear - year
    }

    var nextOccurrenceWeekdayAndDate: String {
        Self.weekdayDateFormatter.string(from: nextOccurrence)
    }

    var formattedDate: String {
        if let year = eventYear {
            let date = Calendar.current.date(from: DateComponents(year: year, month: eventMonth, day: eventDay)) ?? Date()
            return Self.dayMonthYearFormatter.string(from: date)
        } else {
            let date = Calendar.current.date(from: DateComponents(year: 2000, month: eventMonth, day: eventDay)) ?? Date()
            return Self.dayMonthFormatter.string(from: date)
        }
    }

    private static let weekdayDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f
    }()

    private static let dayMonthYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy"
        return f
    }()

    private static let dayMonthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        return f
    }()

    init(
        name: String,
        notes: String = "",
        eventDay: Int = 1,
        eventMonth: Int = 1,
        eventYear: Int? = nil,
        iconName: String = "calendar",
        colorHex: String = "007AFF"
    ) {
        self.name = name
        self.notes = notes
        self.eventDay = eventDay
        self.eventMonth = eventMonth
        self.eventYear = eventYear
        self.iconName = iconName
        self.colorHex = colorHex
        self.createdAt = .now
    }
}

let eventIconOptions: [String] = [
    // Calendar & Time
    "calendar", "calendar.badge.clock", "clock", "hourglass",
    "alarm", "timer", "calendar.badge.plus", "calendar.circle",
    // Celebrations
    "party.popper", "party.popper.fill", "gift", "gift.fill",
    "balloon", "balloon.2", "balloon.2.fill", "birthday.cake",
    "birthday.cake.fill", "trophy", "trophy.fill", "medal",
    // Hearts & Love
    "heart", "heart.fill", "heart.circle", "heart.circle.fill",
    "heart.text.clipboard", "hands.and.sparkles", "figure.2",
    "figure.2.and.child.holdinghands",
    // Stars & Sparkles
    "star", "star.fill", "star.circle", "star.circle.fill",
    "sparkles", "sparkle", "wand.and.stars", "wand.and.stars.inverse",
    // Travel & Places
    "airplane", "car", "house", "house.fill",
    "building.2", "tent", "mountain.2", "globe.americas",
    // Nature
    "leaf", "leaf.fill", "tree", "tree.fill",
    "flame", "flame.fill", "drop", "sun.max",
    "moon", "cloud.sun", "snowflake", "wind",
    // People & Body
    "person", "person.2", "person.3", "figure.walk",
    "figure.run", "figure.yoga", "brain.head.profile", "hand.thumbsup",
    // Education & Work
    "graduationcap", "graduationcap.fill", "book", "book.fill",
    "pencil", "briefcase", "briefcase.fill", "doc.text",
    // Music & Art
    "music.note", "music.note.list", "guitars", "paintbrush",
    "paintpalette", "camera", "camera.fill", "film",
    // Sports
    "sportscourt", "figure.basketball", "figure.soccer",
    "figure.swimming", "medal.fill", "flag", "flag.fill",
    "flag.checkered",
    // Religion & Symbols
    "cross", "staroflife", "bell", "bell.fill",
    "candle.fill", "hands.clap", "peacesign", "infinity",
    // Food & Drink
    "cup.and.saucer", "fork.knife", "wineglass", "wineglass.fill",
    "birthday.cake", "carrot", "takeoutbag.and.cup.and.straw",
    "waterbottle",
    // Tech & Objects
    "gamecontroller", "headphones", "puzzlepiece", "key",
    "lock.open", "lightbulb", "bolt", "wrench",
    // Animals
    "pawprint", "pawprint.fill", "hare", "tortoise",
    "bird", "fish", "cat", "dog",
]
