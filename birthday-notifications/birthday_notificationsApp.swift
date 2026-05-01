import SwiftData
import SwiftUI

@main
struct birthday_notificationsApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([Person.self, PersonGroup.self, GiftIdea.self, Event.self])
        let config = ModelConfiguration(schema: schema)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            // If migration fails, delete the store and retry
            let url = config.url
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.removeItem(at: url.deletingPathExtension().appendingPathExtension("sqlite-wal"))
            try? FileManager.default.removeItem(at: url.deletingPathExtension().appendingPathExtension("sqlite-shm"))
            do {
                container = try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(Theme.brand)
                .onAppear {
                    NotificationManager.shared.requestPermission()
                }
        }
        .modelContainer(container)
    }
}

struct RootView: View {
    @Query private var people: [Person]
    @Query private var events: [Event]

    /// Hash of every field that ends up rendered in a scheduled notification.
    /// Whenever this changes we reschedule, so edits to a birthday date,
    /// nickname, group membership, gift idea count, etc. are reflected
    /// without waiting for a relaunch.
    private var notificationHash: Int {
        var h = people.count ^ events.count
        for p in people {
            h ^= p.notifyOnDay.hashValue &+ p.notifyOneWeekBefore.hashValue
            h ^= p.birthdayDay.hashValue &+ p.birthdayMonth.hashValue
            h ^= p.firstName.hashValue &+ p.lastName.hashValue &+ p.nickname.hashValue
            h ^= p.giftIdeas.count.hashValue
            h ^= (p.photoData?.count ?? 0).hashValue
            for g in p.groups { h ^= g.name.hashValue }
        }
        for e in events {
            h ^= e.eventDay.hashValue &+ e.eventMonth.hashValue
            h ^= e.name.hashValue &+ e.notes.hashValue
            if let y = e.eventYear { h ^= y.hashValue }
        }
        return h
    }

    var body: some View {
        ContentView()
            .onChange(of: people.count) {
                NotificationManager.shared.scheduleNotifications(for: people, events: events)
            }
            .onChange(of: events.count) {
                NotificationManager.shared.scheduleNotifications(for: people, events: events)
            }
            .onChange(of: notificationHash) {
                NotificationManager.shared.scheduleNotifications(for: people, events: events)
            }
            .onAppear {
                NotificationManager.shared.scheduleNotifications(for: people, events: events)
            }
    }
}
