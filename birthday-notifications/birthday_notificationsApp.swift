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

    private var notificationHash: Int {
        var h = people.count ^ events.count
        for p in people {
            h ^= p.notifyOnDay.hashValue &+ p.notifyOneWeekBefore.hashValue
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
