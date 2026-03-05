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

                Section("Notes") {
                    TextField("Optional", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Event")
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
