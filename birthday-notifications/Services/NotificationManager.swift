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
            scheduleDayOf(person: person, center: center)
            scheduleOneWeekBefore(person: person, center: center)
        }

        for event in events {
            scheduleEventDayOf(event: event, center: center)
            scheduleEventOneWeekBefore(event: event, center: center)
        }
    }

    private func scheduleDayOf(person: Person, center: UNUserNotificationCenter) {
        let content = UNMutableNotificationContent()
        content.title = "Birthday Today!"
        content.body = "\(person.fullName) turns \(person.turnsAge) today!"
        content.sound = .default

        var comps = DateComponents()
        comps.month = person.birthdayMonth
        comps.day = person.birthdayDay
        comps.hour = 6
        comps.minute = 30
        comps.timeZone = TimeZone(identifier: "Europe/Oslo")

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let id = "birthday-day-\(person.persistentModelID.hashValue)"
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    private func scheduleOneWeekBefore(person: Person, center: UNUserNotificationCenter) {
        let cal = Calendar.current
        let thisYear = cal.component(.year, from: Date())
        guard let birthdayThisYear = cal.date(from: DateComponents(
            year: thisYear, month: person.birthdayMonth, day: person.birthdayDay
        )) else { return }

        let birthday = birthdayThisYear >= cal.startOfDay(for: Date())
            ? birthdayThisYear
            : cal.date(from: DateComponents(
                year: thisYear + 1, month: person.birthdayMonth, day: person.birthdayDay
            )) ?? birthdayThisYear

        guard let weekBefore = cal.date(byAdding: .day, value: -7, to: birthday) else { return }
        guard weekBefore > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Birthday in 1 week"
        content.body = "\(person.fullName) turns \(person.turnsAge) next week!"
        content.sound = .default

        var comps = cal.dateComponents([.year, .month, .day], from: weekBefore)
        comps.hour = 8
        comps.minute = 0
        comps.timeZone = TimeZone(identifier: "Europe/Oslo")

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let id = "birthday-week-\(person.persistentModelID.hashValue)"
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    // MARK: - Event Notifications

    private func scheduleEventDayOf(event: Event, center: UNUserNotificationCenter) {
        let content = UNMutableNotificationContent()
        content.title = "\(event.name) Today!"
        content.body = "\(event.name) is today!"
        content.sound = .default

        var comps = DateComponents()
        comps.month = event.eventMonth
        comps.day = event.eventDay
        comps.hour = 6
        comps.minute = 30
        comps.timeZone = TimeZone(identifier: "Europe/Oslo")

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let id = "event-day-\(event.persistentModelID.hashValue)"
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    private func scheduleEventOneWeekBefore(event: Event, center: UNUserNotificationCenter) {
        let cal = Calendar.current
        let thisYear = cal.component(.year, from: Date())
        guard let eventThisYear = cal.date(from: DateComponents(
            year: thisYear, month: event.eventMonth, day: event.eventDay
        )) else { return }

        let eventDate = eventThisYear >= cal.startOfDay(for: Date())
            ? eventThisYear
            : cal.date(from: DateComponents(
                year: thisYear + 1, month: event.eventMonth, day: event.eventDay
            )) ?? eventThisYear

        guard let weekBefore = cal.date(byAdding: .day, value: -7, to: eventDate) else { return }
        guard weekBefore > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(event.name) in 1 week"
        content.body = "\(event.name) is next week!"
        content.sound = .default

        var comps = cal.dateComponents([.year, .month, .day], from: weekBefore)
        comps.hour = 8
        comps.minute = 0
        comps.timeZone = TimeZone(identifier: "Europe/Oslo")

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let id = "event-week-\(event.persistentModelID.hashValue)"
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
