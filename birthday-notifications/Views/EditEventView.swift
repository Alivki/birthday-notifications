import SwiftData
import SwiftUI

struct EditEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var event: Event

    @State private var name: String
    @State private var notes: String
    @State private var selectedMonth: Int
    @State private var selectedDay: Int
    @State private var selectedYear: Int?
    @State private var selectedIcon: String
    @State private var selectedColor: Color

    init(event: Event) {
        self.event = event
        _name = State(initialValue: event.name)
        _notes = State(initialValue: event.notes)
        _selectedMonth = State(initialValue: event.eventMonth)
        _selectedDay = State(initialValue: event.eventDay)
        _selectedYear = State(initialValue: event.eventYear)
        _selectedIcon = State(initialValue: event.iconName)
        _selectedColor = State(initialValue: Color(hex: event.colorHex))
    }

    private var currentYear: Int { Calendar.current.component(.year, from: .now) }

    var body: some View {
        NavigationStack {
            Form {
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

                Section {
                    TextField("Event Name", text: $name)
                }

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

                Section {
                    ColorPicker("Color", selection: $selectedColor, supportsOpacity: false)
                }

                Section {
                    CollapsibleDayMonthYearPicker(
                        title: "Date",
                        day: $selectedDay,
                        month: $selectedMonth,
                        year: $selectedYear,
                        yearRange: (currentYear - 50)...currentYear,
                        initiallyExpanded: false
                    )
                }

                Section("Notes") {
                    TextField("Optional", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                SaveCancelToolbar(
                    saveDisabled: name.trimmingCharacters(in: .whitespaces).isEmpty,
                    onSave: save
                )
            }
        }
    }

    private func save() {
        event.name = name.trimmingCharacters(in: .whitespaces)
        event.notes = notes
        event.eventDay = selectedDay
        event.eventMonth = selectedMonth
        event.eventYear = selectedYear
        event.iconName = selectedIcon
        event.colorHex = selectedColor.toHex()
        dismiss()
    }
}
