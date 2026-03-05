import PhotosUI
import SwiftData
import SwiftUI

struct EditPersonView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PersonGroup.name) private var allGroups: [PersonGroup]

    let person: Person

    @State private var firstName: String
    @State private var lastName: String
    @State private var notes: String
    @State private var selectedDay: Int
    @State private var selectedMonth: Int
    @State private var selectedYear: Int?
    @State private var selectedGroups: Set<PersistentIdentifier>

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var rawUIImage: UIImage?
    @State private var croppedImage: UIImage?
    @State private var showCropper = false
    @State private var showDatePicker = false

    private var currentYear: Int { Calendar.current.component(.year, from: .now) }

    init(person: Person) {
        self.person = person
        _firstName = State(initialValue: person.firstName)
        _lastName = State(initialValue: person.lastName)
        _notes = State(initialValue: person.notes)
        _selectedDay = State(initialValue: person.birthdayDay)
        _selectedMonth = State(initialValue: person.birthdayMonth)
        _selectedYear = State(initialValue: person.birthdayYear)
        _selectedGroups = State(initialValue: Set(person.groups.map(\.persistentModelID)))
    }

    var body: some View {
        NavigationStack {
            Form {
                // Photo
                Section {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        if let croppedImage {
                            Image(uiImage: croppedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(.gray.opacity(0.2), lineWidth: 2))
                        } else {
                            PersonPhoto(person: person, size: 120)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)

                // Name
                Section {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                }

                // Group
                Section {
                    NavigationLink {
                        GroupSelectionView(selectedGroups: $selectedGroups)
                    } label: {
                        HStack {
                            Text("Group")
                            Spacer()
                            Text(selectedGroups.isEmpty ? "No" : groupNames)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Birthday
                Section {
                    VStack(spacing: 12) {
                        Button {
                            withAnimation(.spring(duration: 0.4, bounce: 0.1)) {
                                showDatePicker.toggle()
                            }
                        } label: {
                            HStack {
                                Text("Birthday")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text(shortBirthday)
                                    .foregroundStyle(.blue)
                                Image(systemName: "chevron.down")
                                    .font(.caption2.weight(.semibold))
                                    .rotationEffect(.degrees(showDatePicker ? 0 : -90))
                                    .foregroundStyle(.blue)
                            }
                        }

                        if showDatePicker {
                            HStack(spacing: 0) {
                                Picker("", selection: $selectedDay) {
                                    ForEach(1...daysInMonth, id: \.self) { d in
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
                                    ForEach(1900...currentYear, id: \.self) { y in
                                        Text(String(y)).tag(y)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(maxWidth: .infinity)
                            }
                            .frame(height: 180)
                            .clipped()
                        }
                    }
                    .animation(.spring(duration: 0.4, bounce: 0.1), value: showDatePicker)
                }

                // Notes
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit")
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
                        .disabled(firstName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onChange(of: selectedPhoto) {
                Task {
                    if let data = try? await selectedPhoto?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        rawUIImage = uiImage
                        showCropper = true
                    }
                }
            }
            .fullScreenCover(isPresented: $showCropper) {
                if let rawUIImage {
                    ImageCropperView(image: rawUIImage) { cropped in
                        croppedImage = cropped
                    }
                }
            }
        }
    }

    // MARK: - Computed

    private var yearBinding: Binding<Int> {
        Binding(
            get: { selectedYear ?? currentYear + 1 },
            set: { selectedYear = $0 > currentYear ? nil : $0 }
        )
    }

    private var daysInMonth: Int {
        let yr = selectedYear ?? 2000
        let date = Calendar.current.date(from: DateComponents(year: yr, month: selectedMonth))!
        return Calendar.current.range(of: .day, in: .month, for: date)!.count
    }

    private var shortBirthday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        let date = Calendar.current.date(from: DateComponents(year: 2000, month: selectedMonth, day: selectedDay))!
        return formatter.string(from: date)
    }

    private var groupNames: String {
        allGroups.filter { selectedGroups.contains($0.id) }.map(\.name).joined(separator: ", ")
    }

    // MARK: - Save

    private func save() {
        person.firstName = firstName
        person.lastName = lastName
        person.notes = notes
        person.birthdayDay = selectedDay
        person.birthdayMonth = selectedMonth
        person.birthdayYear = selectedYear ?? Calendar.current.component(.year, from: .now)

        if let croppedImage {
            person.photoData = croppedImage.jpegData(compressionQuality: 0.9)
        }

        // Update groups
        for group in person.groups {
            group.members.removeAll { $0.id == person.id }
        }
        for group in allGroups where selectedGroups.contains(group.id) {
            if !group.members.contains(where: { $0.id == person.id }) {
                group.members.append(person)
            }
        }

        dismiss()
    }
}
