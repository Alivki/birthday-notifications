import Foundation
import SwiftData

struct BackupData: Codable {
    var people: [PersonBackup]
    var events: [EventBackup]
    var groups: [GroupBackup]
    var exportDate: Date
}

struct PersonBackup: Codable {
    var firstName: String
    var lastName: String
    var nickname: String? = nil
    var notes: String
    var birthdayDay: Int
    var birthdayMonth: Int
    var birthdayYear: Int
    var notifyOnDay: Bool
    var notifyOneWeekBefore: Bool
    var photoBase64: String?
    var groupNames: [String]
    var giftIdeas: [GiftIdeaBackup]
}

struct GiftIdeaBackup: Codable {
    var title: String
    var notes: String
    var estimatedPrice: Double?
    var url: String?
    var isPurchased: Bool
    var photoBase64: String?
}

struct EventBackup: Codable {
    var name: String
    var notes: String
    var eventDay: Int
    var eventMonth: Int
    var eventYear: Int?
    var iconName: String
    var colorHex: String
}

struct GroupBackup: Codable {
    var name: String
    var colorHex: String
}

@MainActor
final class BackupManager {

    static func exportData(people: [Person], events: [Event], groups: [PersonGroup]) -> Data? {
        let groupBackups = groups.map { GroupBackup(name: $0.name, colorHex: $0.colorHex) }

        let peopleBackups = people.map { person in
            PersonBackup(
                firstName: person.firstName,
                lastName: person.lastName,
                nickname: person.nickname.isEmpty ? nil : person.nickname,
                notes: person.notes,
                birthdayDay: person.birthdayDay,
                birthdayMonth: person.birthdayMonth,
                birthdayYear: person.birthdayYear,
                notifyOnDay: person.notifyOnDay,
                notifyOneWeekBefore: person.notifyOneWeekBefore,
                photoBase64: person.photoData?.base64EncodedString(),
                groupNames: person.groups.map(\.name),
                giftIdeas: person.giftIdeas.map { gift in
                    GiftIdeaBackup(
                        title: gift.title,
                        notes: gift.notes,
                        estimatedPrice: gift.estimatedPrice,
                        url: gift.url,
                        isPurchased: gift.isPurchased,
                        photoBase64: gift.photoData?.base64EncodedString()
                    )
                }
            )
        }

        let eventBackups = events.map { event in
            EventBackup(
                name: event.name,
                notes: event.notes,
                eventDay: event.eventDay,
                eventMonth: event.eventMonth,
                eventYear: event.eventYear,
                iconName: event.iconName,
                colorHex: event.colorHex
            )
        }

        let backup = BackupData(
            people: peopleBackups,
            events: eventBackups,
            groups: groupBackups,
            exportDate: .now
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(backup)
    }

    static func importData(from data: Data, into context: ModelContext) throws -> (people: Int, events: Int, groups: Int) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(BackupData.self, from: data)

        // Create groups first (deduplicate by name)
        var groupMap: [String: PersonGroup] = [:]

        // Fetch existing groups
        let existingGroups = (try? context.fetch(FetchDescriptor<PersonGroup>())) ?? []
        for g in existingGroups {
            groupMap[g.name] = g
        }

        var newGroupCount = 0
        for groupBackup in backup.groups {
            if groupMap[groupBackup.name] == nil {
                let group = PersonGroup(name: groupBackup.name, colorHex: groupBackup.colorHex)
                context.insert(group)
                groupMap[groupBackup.name] = group
                newGroupCount += 1
            }
        }

        // Import people
        var newPeopleCount = 0
        for personBackup in backup.people {
            let person = Person(
                firstName: personBackup.firstName,
                lastName: personBackup.lastName,
                nickname: personBackup.nickname ?? "",
                notes: personBackup.notes,
                birthdayDay: personBackup.birthdayDay,
                birthdayMonth: personBackup.birthdayMonth,
                birthdayYear: personBackup.birthdayYear,
                notifyOnDay: personBackup.notifyOnDay,
                notifyOneWeekBefore: personBackup.notifyOneWeekBefore
            )

            if let base64 = personBackup.photoBase64 {
                person.photoData = Data(base64Encoded: base64)
            }

            context.insert(person)

            // Link to groups
            for groupName in personBackup.groupNames {
                if let group = groupMap[groupName] {
                    group.members.append(person)
                }
            }

            // Import gift ideas
            for giftBackup in personBackup.giftIdeas {
                let gift = GiftIdea(
                    title: giftBackup.title,
                    notes: giftBackup.notes,
                    estimatedPrice: giftBackup.estimatedPrice,
                    url: giftBackup.url,
                    isPurchased: giftBackup.isPurchased
                )
                if let base64 = giftBackup.photoBase64 {
                    gift.photoData = Data(base64Encoded: base64)
                }
                gift.person = person
                context.insert(gift)
            }

            newPeopleCount += 1
        }

        // Import events
        var newEventCount = 0
        for eventBackup in backup.events {
            let event = Event(
                name: eventBackup.name,
                notes: eventBackup.notes,
                eventDay: eventBackup.eventDay,
                eventMonth: eventBackup.eventMonth,
                eventYear: eventBackup.eventYear,
                iconName: eventBackup.iconName,
                colorHex: eventBackup.colorHex
            )
            context.insert(event)
            newEventCount += 1
        }

        return (people: newPeopleCount, events: newEventCount, groups: newGroupCount)
    }
}
