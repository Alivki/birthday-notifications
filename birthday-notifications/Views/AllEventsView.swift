import SwiftData
import SwiftUI

struct AllEventsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var people: [Person]
    @Query private var events: [Event]
    @Query(sort: \PersonGroup.name) private var groups: [PersonGroup]
    @State private var searchText = ""
    @State private var selectedGroupFilter: PersistentIdentifier?
    @State private var addItemType: AddItemType?

    private var filteredPeople: [Person] {
        var result = people
        if let gid = selectedGroupFilter {
            result = result.filter { $0.groups.contains(where: { $0.persistentModelID == gid }) }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.fullName.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }

    private var filteredEvents: [Event] {
        if !searchText.isEmpty {
            return events.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        // Hide events when filtering by group (events don't belong to groups)
        if selectedGroupFilter != nil { return [] }
        return Array(events)
    }

    private var monthSections: [(month: Int, name: String, people: [Person], events: [Event])] {
        let cal = Calendar.current
        let currentMonth = cal.component(.month, from: Date())

        var peopleDict: [Int: [Person]] = [:]
        for person in filteredPeople {
            peopleDict[person.birthdayMonth, default: []].append(person)
        }
        for key in peopleDict.keys {
            peopleDict[key]?.sort { $0.birthdayDay < $1.birthdayDay }
        }

        var eventDict: [Int: [Event]] = [:]
        for event in filteredEvents {
            eventDict[event.eventMonth, default: []].append(event)
        }
        for key in eventDict.keys {
            eventDict[key]?.sort { $0.eventDay < $1.eventDay }
        }

        let orderedMonths = (0..<12).map { (currentMonth - 1 + $0) % 12 + 1 }
        let formatter = DateFormatter()

        return orderedMonths.compactMap { month in
            let monthPeople = peopleDict[month] ?? []
            let monthEvents = eventDict[month] ?? []
            guard !monthPeople.isEmpty || !monthEvents.isEmpty else { return nil }
            return (month: month, name: formatter.monthSymbols[month - 1], people: monthPeople, events: monthEvents)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                // Group filter chips
                if !groups.isEmpty {
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                FilterChip(
                                    label: "All",
                                    color: .blue,
                                    isSelected: selectedGroupFilter == nil
                                ) {
                                    selectedGroupFilter = nil
                                }

                                ForEach(groups) { group in
                                    FilterChip(
                                        label: group.name,
                                        color: group.color,
                                        isSelected: selectedGroupFilter == group.persistentModelID
                                    ) {
                                        if selectedGroupFilter == group.persistentModelID {
                                            selectedGroupFilter = nil
                                        } else {
                                            selectedGroupFilter = group.persistentModelID
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }

                // Month sections
                ForEach(monthSections, id: \.month) { section in
                    Section(section.name) {
                        ForEach(section.events) { event in
                            NavigationLink(value: event.persistentModelID) {
                                EventRow(event: event)
                            }
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                modelContext.delete(section.events[index])
                            }
                        }

                        ForEach(section.people) { person in
                            NavigationLink(value: person.persistentModelID) {
                                PersonRow(person: person)
                            }
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                modelContext.delete(section.people[index])
                            }
                        }
                    }
                }
            }
            .navigationTitle("All Events")
            .searchable(text: $searchText, prompt: "Search")
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
