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
    @State private var toastMessage: String?

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
                                    color: Theme.brand,
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
                            .padding(.horizontal, 16)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 4, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }

                // Month sections
                ForEach(monthSections, id: \.month) { section in
                    Section {
                        HStack(alignment: .firstTextBaseline) {
                            Text(section.name)
                                .font(.system(.title3).weight(.bold))
                                .foregroundStyle(.primary)
                            Text("\(section.people.count + section.events.count)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.textSecondary)
                                .monospacedDigit()
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 18)
                        .padding(.bottom, 6)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    Section {
                        ForEach(section.events) { event in
                            CardLink(value: event.persistentModelID) {
                                EventRow(event: event)
                            }
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                modelContext.delete(section.events[index])
                            }
                        }

                        ForEach(section.people) { person in
                            CardLink(value: person.persistentModelID) {
                                PersonRow(person: person)
                            }
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                modelContext.delete(section.people[index])
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.surface)
            .navigationTitle("All")
            .searchable(text: $searchText, prompt: "Search names and events")
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
                        "Nothing to remember yet",
                        systemImage: "calendar.badge.plus",
                        description: Text("Tap + to add a person or an event.")
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
                    AddPersonView(onSaved: {
                        toastMessage = "Person added"
                    })
                case .event:
                    AddEventView(onSaved: {
                        toastMessage = "Event added"
                    })
                }
            }
            .overlay(alignment: .bottom) {
                ToastView(message: $toastMessage)
            }
        }
    }
}
