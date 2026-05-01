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

    private var currentDateLine: String {
        Self.weekdayDayFormatter.string(from: Date())
    }

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM"
        return f
    }()

    private static let weekdayDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f
    }()


    @ViewBuilder
    private func sectionHeader(_ title: String, count: Int) -> some View {
        Section {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(.primary)
                Text("\(count)")
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
    }

    private var todayHighlights: [(title: String, subtitle: String)] {
        var items: [(String, String)] = []
        for person in people where person.daysUntilBirthday == 0 {
            items.append((person.fullName, "turns \(person.turnsAge)"))
        }
        for event in events where event.daysUntilEvent == 0 {
            items.append((event.name, event.turnsYears.map { $0 == 1 ? "1 year" : "\($0) years" } ?? "today"))
        }
        return items
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

    var body: some View {
        let bdMonth = birthdaysThisMonth
        let evMonth = eventsThisMonth
        let monthCount = bdMonth.count + evMonth.count
        let bdSoon = next30DaysPeople
        let evSoon = next30DaysEvents

        let highlights = todayHighlights

        return NavigationStack {
            List {
                Section {
                    HeroCard(
                        eyebrow: currentMonthName.uppercased() + " · " + currentDateLine,
                        count: monthCount,
                        peopleCount: bdMonth.count,
                        eventCount: evMonth.count
                    )
                    .plainCardRow()
                }

                if !highlights.isEmpty {
                    Section {
                        TodayCard(items: highlights)
                            .plainCardRow()
                    }
                }

                if !bdMonth.isEmpty || !evMonth.isEmpty {
                    sectionHeader("This month", count: bdMonth.count + evMonth.count)
                    Section {
                        ForEach(evMonth) { event in
                            CardLink(value: event.persistentModelID) {
                                EventRow(event: event)
                            }
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        .onDelete { offsets in
                            for i in offsets { modelContext.delete(evMonth[i]) }
                        }

                        ForEach(bdMonth) { person in
                            CardLink(value: person.persistentModelID) {
                                PersonRow(person: person)
                            }
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        .onDelete { offsets in
                            for i in offsets { modelContext.delete(bdMonth[i]) }
                        }
                    }
                }

                if !bdSoon.isEmpty || !evSoon.isEmpty {
                    sectionHeader("Coming up", count: bdSoon.count + evSoon.count)
                    Section {
                        ForEach(evSoon) { event in
                            CardLink(value: event.persistentModelID) {
                                EventRow(event: event)
                            }
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        .onDelete { offsets in
                            for i in offsets { modelContext.delete(evSoon[i]) }
                        }

                        ForEach(bdSoon) { person in
                            CardLink(value: person.persistentModelID) {
                                PersonRow(person: person)
                            }
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        .onDelete { offsets in
                            for i in offsets { modelContext.delete(bdSoon[i]) }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.surface)
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
            PersonPhoto(person: person, size: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(person.displayName)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 5) {
                    Text(person.nextBirthdayWeekdayAndDate)
                        .lineLimit(1)
                    Text("·")
                    Text("turns \(person.turnsAge)")
                        .lineLimit(1)
                }
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            }

            DaysBadge(days: person.daysUntilBirthday)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                .fill(Theme.card)
        )
        .cardShadow()
    }
}

// MARK: - Event Row

struct EventRow: View {
    let event: Event

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(event.color.opacity(0.14))
                    .frame(width: 56, height: 56)
                Image(systemName: event.iconName)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(event.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 5) {
                    Text(event.nextOccurrenceWeekdayAndDate)
                        .lineLimit(1)
                    if let years = event.turnsYears {
                        Text("·")
                        Text("^[\(years) year](inflect: true)")
                            .lineLimit(1)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            }

            DaysBadge(days: event.daysUntilEvent)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                .fill(Theme.card)
        )
        .cardShadow()
    }
}

// MARK: - Days Badge

struct DaysBadge: View {
    let days: Int
    /// Unused for the "chill" case but kept so callers stay simple.
    var accent: Color = Theme.celebration

    var body: some View {
        if days == 0 {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.caption2.weight(.bold))
                Text("Today")
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Theme.celebration))
        } else if days <= 7 {
            VStack(spacing: -1) {
                Text("\(days)")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.celebration)
                Text(days == 1 ? "day" : "days")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.celebration.opacity(0.75))
            }
            .frame(width: 54, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.celebration.opacity(0.10))
            )
        } else {
            HStack(spacing: 3) {
                Text("\(days)")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .monospacedDigit()
                Text("d")
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(Theme.textSecondary)
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

// MARK: - Identifiable image (for sheet/cover bindings)

struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

// MARK: - List row helper

extension View {
    func plainCardRow() -> some View {
        self
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}

/// Wraps a card in an invisible NavigationLink so the System chevron isn't drawn.
/// The visible card sits in front; the link fills the row underneath.
struct CardLink<Content: View, Value: Hashable>: View {
    let value: Value
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            NavigationLink(value: value) { EmptyView() }
                .opacity(0)
            content()
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Hero card

struct HeroCard: View {
    let eyebrow: String
    let count: Int
    let peopleCount: Int
    let eventCount: Int

    private var breakdownText: Text {
        let dot = Text(" · ").foregroundStyle(Theme.brandDeep.opacity(0.4))
        let bd = Text("^[\(peopleCount) birthday](inflect: true)")
        let ev = Text("^[\(eventCount) event](inflect: true)")
        if peopleCount > 0 && eventCount > 0 { return bd + dot + ev }
        if peopleCount > 0 { return bd }
        if eventCount > 0 { return ev }
        return Text("nothing scheduled")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(eyebrow)
                .font(.caption2.weight(.bold))
                .tracking(1.4)
                .foregroundStyle(Theme.brandDeep.opacity(0.5))

            HStack(alignment: .lastTextBaseline, spacing: 10) {
                Text("\(count)")
                    .font(.system(size: 72, weight: .heavy, design: .rounded))
                    .contentTransition(.numericText())
                    .monospacedDigit()
                    .foregroundStyle(Theme.brandDeep)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text(count == 1 ? "thing to remember" : "things to remember")
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.brandDeep)
                    .padding(.bottom, 8)
            }

            breakdownText
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.brandDeep.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: Theme.heroCorner, style: .continuous)
                .fill(Theme.brandSoft)
        )
    }
}

// MARK: - Today card

struct TodayCard: View {
    let items: [(title: String, subtitle: String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text("🎉")
                    .font(.callout)
                Text("TODAY")
                    .font(.caption2.weight(.bold))
                    .tracking(1.6)
                    .foregroundStyle(Theme.celebration)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(items.indices, id: \.self) { i in
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(items[i].title)
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundStyle(.primary)
                        Text(items[i].subtitle)
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                .fill(Theme.celebrationSoft)
        )
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
    let accent: Color
    @ViewBuilder let icon: () -> Icon
    @ViewBuilder let chips: () -> Chips
    let pills: [DetailPill]

    var body: some View {
        VStack(spacing: 16) {
            icon()
                .padding(.top, 8)

            VStack(spacing: 4) {
                Text(title)
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            chips()

            HStack(spacing: 8) {
                ForEach(pills) { pill in
                    CountdownPill(title: pill.title, accent: pill.accent, filled: pill.filled)
                }
            }
            .padding(.bottom, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: Theme.heroCorner, style: .continuous)
                .fill(accent.opacity(0.10))
        )
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
            HStack(spacing: 6) {
                if isSelected {
                    Circle()
                        .fill(.white)
                        .frame(width: 6, height: 6)
                }
                Text(label)
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? color : Theme.card, in: Capsule())
            .foregroundStyle(isSelected ? .white : .primary)
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.black.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
