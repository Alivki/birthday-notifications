import SwiftData
import SwiftUI

struct AddEventView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var onSaved: (() -> Void)?

    @State private var name = ""
    @State private var notes = ""
    @State private var selectedMonth = Calendar.current.component(.month, from: .now)
    @State private var selectedDay = Calendar.current.component(.day, from: .now)
    @State private var selectedYear: Int? = nil
    @State private var selectedIcon = "calendar"
    @State private var selectedColor: Color = .blue

    @FocusState private var nameFocused: Bool

    private var currentYear: Int { Calendar.current.component(.year, from: .now) }

    var body: some View {
        NavigationStack {
            Form {
                iconPreviewSection
                nameSection
                iconPickerSection
                colorPickerSection
                dateSection
                notesSection
            }
            .navigationTitle("Add Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                SaveCancelToolbar(
                    saveDisabled: name.trimmingCharacters(in: .whitespaces).isEmpty,
                    onSave: save
                )
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var iconPreviewSection: some View {
        Section {
            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .fill(selectedColor.opacity(0.15))
                        .frame(width: 100, height: 100)
                    Image(systemName: selectedIcon)
                        .font(.system(size: 38))
                        .foregroundStyle(selectedColor)
                }
                Spacer()
            }
        }
        .listRowBackground(Color.clear)
    }

    @ViewBuilder
    private var nameSection: some View {
        Section {
            TextField("Event name", text: $name)
                .focused($nameFocused)
        }
    }

    @ViewBuilder
    private var iconPickerSection: some View {
        Section("Icon") {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: Array(repeating: GridItem(.fixed(44)), count: 4), spacing: 8) {
                    ForEach(eventIconOptions, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                        } label: {
                            Image(systemName: icon)
                                .font(.system(size: 18))
                                .frame(width: 40, height: 40)
                                .background(
                                    selectedIcon == icon
                                        ? selectedColor.opacity(0.2)
                                        : Color(.systemGray6),
                                    in: RoundedRectangle(cornerRadius: 8)
                                )
                                .foregroundStyle(selectedIcon == icon ? selectedColor : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    @ViewBuilder
    private var colorPickerSection: some View {
        Section {
            ColorPicker("Color", selection: $selectedColor, supportsOpacity: false)
        }
    }

    @ViewBuilder
    private var dateSection: some View {
        Section {
            CollapsibleDayMonthYearPicker(
                title: "Date",
                day: $selectedDay,
                month: $selectedMonth,
                year: $selectedYear,
                yearRange: (currentYear - 50)...currentYear,
                nextLabel: "Next",
                nextValue: daysUntilEvent == 0 ? "Today" : "\(daysUntilEvent) \(daysUntilEvent == 1 ? "day" : "days")"
            )
        }
    }

    @ViewBuilder
    private var notesSection: some View {
        Section("Notes") {
            TextField("Optional", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    // MARK: - Computed

    private var daysUntilEvent: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let thisYear = cal.component(.year, from: today)
        var comps = DateComponents(year: thisYear, month: selectedMonth, day: selectedDay)
        if let candidate = cal.date(from: comps), candidate >= today {
            return cal.dateComponents([.day], from: today, to: candidate).day ?? 0
        }
        comps.year = thisYear + 1
        let next = cal.date(from: comps) ?? today
        return cal.dateComponents([.day], from: today, to: next).day ?? 0
    }

    // MARK: - Actions

    private func save() {
        let event = Event(
            name: name.trimmingCharacters(in: .whitespaces),
            notes: notes,
            eventDay: selectedDay,
            eventMonth: selectedMonth,
            eventYear: selectedYear,
            iconName: selectedIcon,
            colorHex: selectedColor.toHex()
        )
        modelContext.insert(event)
        onSaved?()
        dismiss()
    }
}
