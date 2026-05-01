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
    @State private var nickname: String
    @State private var notes: String
    @State private var selectedDay: Int
    @State private var selectedMonth: Int
    @State private var selectedYear: Int?
    @State private var selectedGroups: Set<PersistentIdentifier>

    @State private var notifyOnDay: Bool
    @State private var notifyOneWeekBefore: Bool

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var cropperImage: IdentifiableImage?
    @State private var croppedImage: UIImage?

    private var currentYear: Int { Calendar.current.component(.year, from: .now) }

    init(person: Person) {
        self.person = person
        _firstName = State(initialValue: person.firstName)
        _lastName = State(initialValue: person.lastName)
        _nickname = State(initialValue: person.nickname)
        _notes = State(initialValue: person.notes)
        _selectedDay = State(initialValue: person.birthdayDay)
        _selectedMonth = State(initialValue: person.birthdayMonth)
        _selectedYear = State(initialValue: person.birthdayYear)
        _selectedGroups = State(initialValue: Set(person.groups.map(\.persistentModelID)))
        _notifyOnDay = State(initialValue: person.notifyOnDay)
        _notifyOneWeekBefore = State(initialValue: person.notifyOneWeekBefore)
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
                    TextField("First name", text: $firstName)
                        .textContentType(.givenName)
                    TextField("Last name", text: $lastName)
                        .textContentType(.familyName)
                }
                Section {
                    TextField("Nickname", text: $nickname)
                        .textContentType(.nickname)
                } footer: {
                    Text("Shown on the home screen if set.")
                }

                // Group
                Section {
                    NavigationLink {
                        GroupSelectionView(selectedGroups: $selectedGroups)
                    } label: {
                        HStack {
                            Text("Groups")
                            Spacer()
                            Text(selectedGroups.isEmpty ? "None" : groupNames)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Birthday
                Section {
                    CollapsibleDayMonthYearPicker(
                        title: "Birthday",
                        day: $selectedDay,
                        month: $selectedMonth,
                        year: $selectedYear,
                        yearRange: 1900...currentYear,
                        initiallyExpanded: false
                    )
                }

                // Notifications
                Section("Notifications") {
                    Toggle("On the day", isOn: $notifyOnDay)
                    Toggle("One week before", isOn: $notifyOneWeekBefore)
                }

                // Notes
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                SaveCancelToolbar(
                    saveDisabled: firstName.trimmingCharacters(in: .whitespaces).isEmpty,
                    onSave: save
                )
            }
            .onChange(of: selectedPhoto) {
                Task {
                    if let data = try? await selectedPhoto?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        cropperImage = IdentifiableImage(image: uiImage)
                    }
                }
            }
            .fullScreenCover(item: $cropperImage) { item in
                ImageCropperView(image: item.image) { cropped in
                    croppedImage = cropped
                }
            }
        }
    }

    // MARK: - Computed

    private var groupNames: String {
        allGroups.filter { selectedGroups.contains($0.id) }.map(\.name).joined(separator: ", ")
    }

    // MARK: - Save

    private func save() {
        person.firstName = firstName
        person.lastName = lastName
        person.nickname = nickname.trimmingCharacters(in: .whitespaces)
        person.notes = notes
        person.birthdayDay = selectedDay
        person.birthdayMonth = selectedMonth
        person.birthdayYear = selectedYear ?? Calendar.current.component(.year, from: .now)
        person.notifyOnDay = notifyOnDay
        person.notifyOneWeekBefore = notifyOneWeekBefore

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
