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
    @State private var toastMessage: String?

    private var currentMonthName: String {
        Self.monthFormatter.string(from: Date())
    }

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM"
        return f
    }()

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

    var body: some View {
        let bdMonth = birthdaysThisMonth
        let evMonth = eventsThisMonth
        let monthCount = bdMonth.count + evMonth.count
        let bdSoon = next30DaysPeople
        let evSoon = next30DaysEvents

        return NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(currentMonthName.uppercased())
                            .font(.caption.weight(.semibold))
                            .tracking(1.2)
                            .foregroundStyle(.secondary)

                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("\(monthCount)")
                                .font(.system(size: 52, weight: .bold, design: .rounded))
                                .contentTransition(.numericText())
                                .monospacedDigit()

                            Text("^[\(monthCount) thing](inflect: true) to remember")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowSeparator(.hidden)
                }

                if !bdMonth.isEmpty || !evMonth.isEmpty {
                    Section("This month") {
                        ForEach(evMonth) { event in
                            NavigationLink(value: event.persistentModelID) {
                                EventRow(event: event)
                            }
                        }
                        .onDelete { offsets in
                            for i in offsets { modelContext.delete(evMonth[i]) }
                        }

                        ForEach(bdMonth) { person in
                            NavigationLink(value: person.persistentModelID) {
                                PersonRow(person: person)
                            }
                        }
                        .onDelete { offsets in
                            for i in offsets { modelContext.delete(bdMonth[i]) }
                        }
                    }
                }

                if !bdSoon.isEmpty || !evSoon.isEmpty {
                    Section("Coming up") {
                        ForEach(evSoon) { event in
                            NavigationLink(value: event.persistentModelID) {
                                EventRow(event: event)
                            }
                        }
                        .onDelete { offsets in
                            for i in offsets { modelContext.delete(evSoon[i]) }
                        }

                        ForEach(bdSoon) { person in
                            NavigationLink(value: person.persistentModelID) {
                                PersonRow(person: person)
                            }
                        }
                        .onDelete { offsets in
                            for i in offsets { modelContext.delete(bdSoon[i]) }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
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

// MARK: - Person Row

struct PersonRow: View {
    let person: Person

    var body: some View {
        HStack(spacing: 14) {
            PersonPhoto(person: person, size: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text(person.fullName)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 6) {
                    Text(person.nextBirthdayWeekdayAndDate)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text("·")
                        .foregroundStyle(.secondary)

                    Text("turns \(person.turnsAge)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            DaysBadge(days: person.daysUntilBirthday, accent: .pink)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Event Row

struct EventRow: View {
    let event: Event

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(event.color.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: event.iconName)
                    .font(.title3)
                    .foregroundStyle(event.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(event.name)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 6) {
                    Text(event.nextOccurrenceWeekdayAndDate)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    if let years = event.turnsYears {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text("^[\(years) year](inflect: true)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            DaysBadge(days: event.daysUntilEvent, accent: event.color)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Days Badge

struct DaysBadge: View {
    let days: Int
    let accent: Color

    var body: some View {
        if days == 0 {
            Text("Today")
                .font(.caption.weight(.semibold))
                .foregroundStyle(accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(accent.opacity(0.14), in: Capsule())
        } else {
            VStack(alignment: .trailing, spacing: 0) {
                Text("\(days)")
                    .font(.callout.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                Text(days == 1 ? "day" : "days")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
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

// MARK: - Helpers

func daysUntilLabel(_ days: Int) -> String {
    if days == 0 { return "Today" }
    return "In \(days) \(days == 1 ? "day" : "days")"
}

// MARK: - Collapsible day/month/year picker

struct CollapsibleDayMonthYearPicker: View {
    let title: String
    @Binding var day: Int
    @Binding var month: Int
    @Binding var year: Int?
    let yearRange: ClosedRange<Int>
    var nextLabel: String?
    var nextValue: String?

    @State private var expanded: Bool

    init(
        title: String,
        day: Binding<Int>,
        month: Binding<Int>,
        year: Binding<Int?>,
        yearRange: ClosedRange<Int>,
        initiallyExpanded: Bool = true,
        nextLabel: String? = nil,
        nextValue: String? = nil
    ) {
        self.title = title
        self._day = day
        self._month = month
        self._year = year
        self.yearRange = yearRange
        self.nextLabel = nextLabel
        self.nextValue = nextValue
        _expanded = State(initialValue: initiallyExpanded)
    }

    private var unspecifiedYearTag: Int { yearRange.upperBound + 1 }

    private var yearBinding: Binding<Int> {
        Binding(
            get: { year ?? unspecifiedYearTag },
            set: { year = $0 > yearRange.upperBound ? nil : $0 }
        )
    }

    private var daysInSelectedMonth: Int {
        let yr = year ?? 2000
        let date = Calendar.current.date(from: DateComponents(year: yr, month: month))!
        return Calendar.current.range(of: .day, in: .month, for: date)!.count
    }

    private var shortDate: String {
        if let y = year {
            let date = Calendar.current.date(from: DateComponents(year: y, month: month, day: day))!
            return Self.monthDayYearFormatter.string(from: date)
        } else {
            let date = Calendar.current.date(from: DateComponents(year: 2000, month: month, day: day))!
            return Self.monthDayFormatter.string(from: date)
        }
    }

    private static let monthDayYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM dd, yyyy"
        return f
    }()

    private static let monthDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM dd"
        return f
    }()

    private static let monthSymbols: [String] = DateFormatter().monthSymbols

    var body: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation(.spring(duration: 0.4, bounce: 0.1)) {
                    expanded.toggle()
                }
            } label: {
                HStack {
                    Text(title)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(shortDate)
                        .foregroundStyle(.tint)
                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.semibold))
                        .rotationEffect(.degrees(expanded ? 0 : -90))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if expanded {
                HStack(spacing: 0) {
                    Picker("", selection: $day) {
                        ForEach(1...daysInSelectedMonth, id: \.self) { d in
                            Text("\(d)").tag(d)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)

                    Picker("", selection: $month) {
                        ForEach(1...12, id: \.self) { m in
                            Text(Self.monthName(m)).tag(m)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)

                    Picker("", selection: yearBinding) {
                        Text("---").tag(unspecifiedYearTag)
                        ForEach(yearRange, id: \.self) { y in
                            Text(String(y)).tag(y)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 180)
                .clipped()
            }

            if let nextLabel, let nextValue {
                Divider()

                HStack {
                    Text(nextLabel)
                    Spacer()
                    Text(nextValue)
                        .fontWeight(nextValue == "Today" ? .semibold : .regular)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .animation(.spring(duration: 0.4, bounce: 0.1), value: expanded)
    }

    static func monthName(_ month: Int) -> String {
        monthSymbols[month - 1]
    }
}

// MARK: - Group chip

struct GroupChip: View {
    let group: PersonGroup

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(group.color)
                .frame(width: 7, height: 7)
            Text(group.name)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(group.color.opacity(0.12), in: Capsule())
        .foregroundStyle(group.color)
    }
}

// MARK: - Detail header

struct DetailPill: Identifiable {
    let id = UUID()
    let title: String
    let accent: Color
    let filled: Bool
}

struct DetailHeader<Icon: View, Chips: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let icon: () -> Icon
    @ViewBuilder let chips: () -> Chips
    let pills: [DetailPill]

    var body: some View {
        VStack(spacing: 14) {
            icon()

            VStack(spacing: 4) {
                Text(title)
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            chips()

            HStack(spacing: 8) {
                ForEach(pills) { pill in
                    CountdownPill(title: pill.title, accent: pill.accent, filled: pill.filled)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

// MARK: - Save / Cancel toolbar

struct SaveCancelToolbar: ToolbarContent {
    @Environment(\.dismiss) private var dismiss
    let saveDisabled: Bool
    let onSave: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Save", action: onSave)
                .fontWeight(.semibold)
                .disabled(saveDisabled)
        }
    }
}

// MARK: - Countdown Pill

struct CountdownPill: View {
    let title: String
    let accent: Color
    var filled: Bool = true

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 11)
            .padding(.vertical, 5)
            .foregroundStyle(accent)
            .background(filled ? accent.opacity(0.14) : Color.clear, in: Capsule())
            .overlay(
                Capsule().stroke(filled ? Color.clear : accent.opacity(0.35), lineWidth: 1)
            )
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
