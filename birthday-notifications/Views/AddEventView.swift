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
    @State private var showDatePicker = true

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
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .tint(.blue)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
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
            TextField("Event Name", text: $name)
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
            VStack(spacing: 12) {
                Button {
                    showDatePicker.toggle()
                } label: {
                    HStack {
                        Text("Date")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(shortDate)
                            .foregroundStyle(.blue)
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.semibold))
                            .rotationEffect(.degrees(showDatePicker ? 0 : -90))
                            .foregroundStyle(.blue)
                    }
                }
                .buttonStyle(.plain)

                if showDatePicker {
                    HStack(spacing: 0) {
                        Picker("", selection: $selectedDay) {
                            ForEach(1...daysInSelectedMonth, id: \.self) { d in
                                Text("\(d)").tag(d)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)

                        Picker("", selection: $selectedMonth) {
                            ForEach(1...12, id: \.self) { m in
                                Text(AddPersonView.monthName(m)).tag(m)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)

                        Picker("", selection: yearBinding) {
                            Text("---").tag(currentYear + 1)
                            ForEach((currentYear - 50)...currentYear, id: \.self) { y in
                                Text(String(y)).tag(y)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                    }
                    .frame(height: 180)
                    .clipped()
                }

                Divider()

                HStack {
                    Text("Next")
                    Spacer()
                    if daysUntilEvent == 0 {
                        Text("Today!")
                    } else {
                        Text("\(daysUntilEvent) days")
                    }
                }
                .foregroundStyle(.secondary)
            }
            .animation(.spring(duration: 0.4, bounce: 0.1), value: showDatePicker)
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

    private var yearBinding: Binding<Int> {
        Binding(
            get: { selectedYear ?? currentYear + 1 },
            set: { selectedYear = $0 > currentYear ? nil : $0 }
        )
    }

    private var daysInSelectedMonth: Int {
        let yr = selectedYear ?? 2000
        let date = Calendar.current.date(from: DateComponents(year: yr, month: selectedMonth))!
        return Calendar.current.range(of: .day, in: .month, for: date)!.count
    }

    private var shortDate: String {
        let formatter = DateFormatter()
        if let year = selectedYear {
            formatter.dateFormat = "MMM dd, yyyy"
            let date = Calendar.current.date(from: DateComponents(year: year, month: selectedMonth, day: selectedDay))!
            return formatter.string(from: date)
        } else {
            formatter.dateFormat = "MMM dd"
            let date = Calendar.current.date(from: DateComponents(year: 2000, month: selectedMonth, day: selectedDay))!
            return formatter.string(from: date)
        }
    }

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
