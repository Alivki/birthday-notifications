import Foundation
import SwiftData
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func scheduleNotifications(for people: [Person], events: [Event]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        for person in people {
            if person.notifyOnDay {
                scheduleBirthdayDayOf(person: person, center: center)
            }
            if person.notifyOneWeekBefore {
                scheduleBirthdayWeekBefore(person: person, center: center)
            }
        }

        for event in events {
            scheduleEventDayOf(event: event, center: center)
            scheduleEventWeekBefore(event: event, center: center)
        }
    }

    // MARK: - Person notifications

    private func scheduleBirthdayDayOf(person: Person, center: UNUserNotificationCenter) {
        guard let birthday = nextOccurrence(month: person.birthdayMonth, day: person.birthdayDay) else { return }

        let content = UNMutableNotificationContent()
        content.title = "🎂 \(person.displayName)'s birthday"
        content.subtitle = "Turning \(person.turnsAge) today"
        content.body = personBodyExtras(person)
        content.sound = .default
        content.threadIdentifier = threadID(for: person)
        attachPhoto(person, to: content)

        let trigger = calendarTrigger(for: birthday, hour: 6, minute: 30)
        let id = "birthday-day-\(person.persistentModelID.hashValue)"
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    private func scheduleBirthdayWeekBefore(person: Person, center: UNUserNotificationCenter) {
        guard let birthday = nextOccurrence(month: person.birthdayMonth, day: person.birthdayDay),
              let weekBefore = Calendar.current.date(byAdding: .day, value: -7, to: birthday),
              weekBefore > Date() else { return }

        let content = UNMutableNotificationContent()
        let firstName = personFirstName(person)
        content.title = "🎁 \(firstName)'s birthday in 1 week"
        content.subtitle = "Turning \(person.turnsAge) on \(Self.weekdayDateFormatter.string(from: birthday))"
        content.body = personBodyExtras(person, fallback: "Time to plan something special.")
        content.sound = .default
        content.threadIdentifier = threadID(for: person)
        attachPhoto(person, to: content)

        let trigger = calendarTrigger(for: weekBefore, hour: 8, minute: 0)
        let id = "birthday-week-\(person.persistentModelID.hashValue)"
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    /// Writes the person's photo to a temp file and adds it as an attachment.
    /// `UNUserNotificationCenter.add` copies the file into its own sandbox, so
    /// the temp file doesn't need explicit cleanup beyond what iOS already
    /// does for the temporary directory.
    private func attachPhoto(_ person: Person, to content: UNMutableNotificationContent) {
        guard let data = person.photoData else { return }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("notif-\(UUID().uuidString).jpg")
        do {
            try data.write(to: url)
            let attachment = try UNNotificationAttachment(identifier: "photo", url: url, options: nil)
            content.attachments = [attachment]
        } catch {
            // Silently skip — notification still fires without the photo.
        }
    }

    // MARK: - Event notifications

    private func scheduleEventDayOf(event: Event, center: UNUserNotificationCenter) {
        guard let occurrence = nextOccurrence(month: event.eventMonth, day: event.eventDay) else { return }

        let content = UNMutableNotificationContent()
        if let years = event.turnsYears {
            content.title = "🎉 \(event.name) · \(yearsLabel(years))"
        } else {
            content.title = "🗓 \(event.name) today"
        }
        content.subtitle = Self.weekdayDateFormatter.string(from: occurrence)
        content.body = event.notes.isEmpty ? "Today's the day." : event.notes
        content.sound = .default
        content.threadIdentifier = threadID(for: event)

        let trigger = calendarTrigger(for: occurrence, hour: 6, minute: 30)
        let id = "event-day-\(event.persistentModelID.hashValue)"
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    private func scheduleEventWeekBefore(event: Event, center: UNUserNotificationCenter) {
        guard let occurrence = nextOccurrence(month: event.eventMonth, day: event.eventDay),
              let weekBefore = Calendar.current.date(byAdding: .day, value: -7, to: occurrence),
              weekBefore > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "🗓 \(event.name) in 1 week"
        let dayString = Self.weekdayDateFormatter.string(from: occurrence)
        if let years = event.turnsYears {
            content.subtitle = "\(yearsLabel(years)) on \(dayString)"
        } else {
            content.subtitle = dayString
        }
        content.body = event.notes.isEmpty ? "Coming up next week." : event.notes
        content.sound = .default
        content.threadIdentifier = threadID(for: event)

        let trigger = calendarTrigger(for: weekBefore, hour: 8, minute: 0)
        let id = "event-week-\(event.persistentModelID.hashValue)"
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    // MARK: - Content builders

    private func personBodyExtras(_ person: Person, fallback: String = "") -> String {
        var parts: [String] = []
        if !person.groups.isEmpty {
            parts.append(person.groups.map(\.name).joined(separator: ", "))
        }
        if !person.giftIdeas.isEmpty {
            let n = person.giftIdeas.count
            parts.append(n == 1 ? "1 gift idea saved" : "\(n) gift ideas saved")
        }
        if parts.isEmpty { return fallback }
        return parts.joined(separator: " · ")
    }

    private func personFirstName(_ person: Person) -> String {
        let trimmed = person.firstName.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? person.displayName : trimmed
    }

    private func yearsLabel(_ years: Int) -> String {
        years == 1 ? "1 year" : "\(years) years"
    }

    private func threadID(for person: Person) -> String {
        "person-\(person.persistentModelID.hashValue)"
    }

    private func threadID(for event: Event) -> String {
        "event-\(event.persistentModelID.hashValue)"
    }

    // MARK: - Date helpers

    /// Next occurrence (this year if not yet passed, otherwise next year).
    private func nextOccurrence(month: Int, day: Int) -> Date? {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let thisYear = cal.component(.year, from: today)

        var comps = DateComponents(year: thisYear, month: month, day: day)
        if let candidate = cal.date(from: comps), candidate >= today {
            return candidate
        }
        comps.year = thisYear + 1
        return cal.date(from: comps)
    }

    /// Calendar trigger for a specific date at a given local time. Non-repeating —
    /// the app reschedules whenever it launches or data changes, which keeps
    /// rich content (age, group names, gift counts) fresh year to year.
    private func calendarTrigger(for date: Date, hour: Int, minute: Int) -> UNCalendarNotificationTrigger {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        comps.hour = hour
        comps.minute = minute
        comps.timeZone = Self.timezone
        return UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
    }

    private static let timezone = TimeZone(identifier: "Europe/Oslo")

    private static let weekdayDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f
    }()
}
