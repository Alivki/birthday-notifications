import SwiftData
import SwiftUI

enum AddItemType: String, Identifiable {
    case person, event
    var id: String { rawValue }
}

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var people: [Person]
    @Query private var events: [Event]
    @State private var addItemType: AddItemType?
    @State private var showingAddSheet = false

    private var currentMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }

    private var birthdaysThisMonth: [Person] {
        let currentMonth = Calendar.current.component(.month, from: Date())
        return people
            .filter { $0.birthdayMonth == currentMonth }
            .sorted { $0.birthdayDay < $1.birthdayDay }
    }

    private var eventsThisMonth: [Event] {
        let currentMonth = Calendar.current.component(.month, from: Date())
        return events
            .filter { $0.eventMonth == currentMonth }
            .sorted { $0.eventDay < $1.eventDay }
    }

    private var next30DaysPeople: [Person] {
        let currentMonth = Calendar.current.component(.month, from: Date())
        return people
            .filter { $0.daysUntilBirthday > 0 && $0.daysUntilBirthday <= 30 && $0.birthdayMonth != currentMonth }
            .sorted { $0.daysUntilBirthday < $1.daysUntilBirthday }
    }

    private var next30DaysEvents: [Event] {
        let currentMonth = Calendar.current.component(.month, from: Date())
        return events
            .filter { $0.daysUntilEvent > 0 && $0.daysUntilEvent <= 30 && $0.eventMonth != currentMonth }
            .sorted { $0.daysUntilEvent < $1.daysUntilEvent }
    }

    private var thisMonthCount: Int {
        birthdaysThisMonth.count + eventsThisMonth.count
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(thisMonthCount)")
                            .font(.system(size: 48, weight: .bold))
                            .contentTransition(.numericText())

                        Text("Events in \(currentMonthName)")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .listRowSeparator(.hidden)
                }

                if !birthdaysThisMonth.isEmpty || !eventsThisMonth.isEmpty {
                    Section("This Month") {
                        ForEach(eventsThisMonth) { event in
                            NavigationLink(value: event.persistentModelID) {
                                EventRow(event: event)
                            }
                        }
                        .onDelete { offsets in
                            for i in offsets { modelContext.delete(eventsThisMonth[i]) }
                        }

                        ForEach(birthdaysThisMonth) { person in
                            NavigationLink(value: person.persistentModelID) {
                                PersonRow(person: person)
                            }
                        }
                        .onDelete { offsets in
                            for i in offsets { modelContext.delete(birthdaysThisMonth[i]) }
                        }
                    }
                }

                if !next30DaysPeople.isEmpty || !next30DaysEvents.isEmpty {
                    Section("Next 30 Days") {
                        ForEach(next30DaysEvents) { event in
                            NavigationLink(value: event.persistentModelID) {
                                EventRow(event: event)
                            }
                        }
                        .onDelete { offsets in
                            for i in offsets { modelContext.delete(next30DaysEvents[i]) }
                        }

                        ForEach(next30DaysPeople) { person in
                            NavigationLink(value: person.persistentModelID) {
                                PersonRow(person: person)
                            }
                        }
                        .onDelete { offsets in
                            for i in offsets { modelContext.delete(next30DaysPeople[i]) }
                        }
                    }
                }
            }
            .navigationTitle("Home")
            .navigationDestination(for: PersistentIdentifier.self) { id in
                if let _ = try? modelContext.model(for: id) as? Event {
                    EventDetailView(eventID: id)
                } else {
                    PersonDetailView(personID: id)
                }
            }
            .overlay {
                if people.isEmpty && events.isEmpty {
                    ContentUnavailableView(
                        "No Events Yet",
                        systemImage: "calendar.badge.plus",
                        description: Text("Tap + to add someone or an event")
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            addItemType = .person
                        } label: {
                            Label("Person", systemImage: "person.fill")
                        }
                        Button {
                            addItemType = .event
                        } label: {
                            Label("Event", systemImage: "calendar")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $addItemType) { type in
                switch type {
                case .person:
                    AddPersonView()
                case .event:
                    AddEventView()
                }
            }
        }
    }
}

// MARK: - Person Row

struct PersonRow: View {
    let person: Person

    var body: some View {
        HStack(spacing: 12) {
            PersonPhoto(person: person, size: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(person.fullName)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 6) {
                    Text("Turns \(person.turnsAge)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.pink)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(.pink.opacity(0.12), in: Capsule())

                    Text(person.nextBirthdayWeekdayAndDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            if person.daysUntilBirthday == 0 {
                HStack(spacing: 3) {
                    Text("Today")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.pink)
                }
            } else {
                Text("In \(person.daysUntilBirthday)d")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Event Row

struct EventRow: View {
    let event: Event

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(event.color.opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: event.iconName)
                    .font(.title3)
                    .foregroundStyle(event.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 6) {
                    if let years = event.turnsYears {
                        Text("\(years) years")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(event.color)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(event.color.opacity(0.12), in: Capsule())
                    }

                    Text(event.nextOccurrenceWeekdayAndDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            if event.daysUntilEvent == 0 {
                Text("Today")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(event.color)
            } else {
                Text("In \(event.daysUntilEvent)d")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Person Photo (reusable)

struct PersonPhoto: View {
    let person: Person
    let size: CGFloat

    var body: some View {
        if let data = person.photoData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(.gray.opacity(0.15))
                .frame(width: size, height: size)
                .overlay(
                    Text(person.firstName.prefix(1).uppercased())
                        .font(.system(size: size * 0.38, weight: .medium))
                        .foregroundStyle(.gray)
                )
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? color.opacity(0.15) : .gray.opacity(0.08), in: Capsule())
                .foregroundStyle(isSelected ? color : .secondary)
        }
    }
}
