import PhotosUI
import SwiftData
import SwiftUI

struct AddPersonView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \PersonGroup.name) private var allGroups: [PersonGroup]

    var onSaved: (() -> Void)?

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var nickname = ""
    @State private var notes = ""

    @State private var selectedYear: Int? = Calendar.current.component(.year, from: .now)
    @State private var selectedMonth = Calendar.current.component(.month, from: .now)
    @State private var selectedDay = Calendar.current.component(.day, from: .now)

    @State private var selectedGroups: Set<PersistentIdentifier> = []
    @State private var notifyOnDay = true
    @State private var notifyOneWeekBefore = true

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var cropperImage: IdentifiableImage?
    @State private var croppedImage: UIImage?

    @FocusState private var firstNameFocused: Bool
    @FocusState private var lastNameFocused: Bool

    private var currentYear: Int { Calendar.current.component(.year, from: .now) }

    var body: some View {
        NavigationStack {
            Form {
                photoSection
                nameSection
                groupSection
                birthdaySection
                notificationsSection
                notesSection
            }
            .navigationTitle("Add Person")
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

    // MARK: - Sections

    @ViewBuilder
    private var photoSection: some View {
        Section {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                if let croppedImage {
                    Image(uiImage: croppedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 160, height: 160)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.gray.opacity(0.2), lineWidth: 3))
                } else {
                    Circle()
                        .fill(.gray.opacity(0.12))
                        .frame(width: 160, height: 160)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(.gray.opacity(0.4))
                        )
                        .overlay(Circle().stroke(.gray.opacity(0.15), lineWidth: 3))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .listRowBackground(Color.clear)
    }

    @ViewBuilder
    private var nameSection: some View {
        Section {
            TextField("First name", text: $firstName)
                .focused($firstNameFocused)
                .textContentType(.givenName)
                .onSubmit { lastNameFocused = true }
            TextField("Last name", text: $lastName)
                .focused($lastNameFocused)
                .textContentType(.familyName)
        }
        Section {
            TextField("Nickname", text: $nickname)
                .textContentType(.nickname)
        } footer: {
            Text("Shown on the home screen if set.")
        }
    }

    @ViewBuilder
    private var groupSection: some View {
        Section {
            NavigationLink {
                GroupSelectionView(selectedGroups: $selectedGroups)
            } label: {
                HStack {
                    Text("Groups")
                    Spacer()
                    Text(groupLabel)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var birthdaySection: some View {
        Section {
            CollapsibleDayMonthYearPicker(
                title: "Birthday",
                day: $selectedDay,
                month: $selectedMonth,
                year: $selectedYear,
                yearRange: 1900...currentYear,
                nextLabel: "Next birthday",
                nextValue: isBirthdayToday ? "Today" : "\(daysUntilBirthday) \(daysUntilBirthday == 1 ? "day" : "days")"
            )
        }
    }

    @ViewBuilder
    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle("On the day", isOn: $notifyOnDay)
            Toggle("One week before", isOn: $notifyOneWeekBefore)
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

    private var isBirthdayToday: Bool {
        let cal = Calendar.current
        let today = Date()
        return cal.component(.month, from: today) == selectedMonth &&
               cal.component(.day, from: today) == selectedDay
    }

    private var daysUntilBirthday: Int {
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

    private var groupLabel: String {
        if selectedGroups.isEmpty { return "None" }
        let names = allGroups.filter { selectedGroups.contains($0.id) }.map(\.name)
        return names.joined(separator: ", ")
    }

    // MARK: - Actions

    private func save() {
        let person = Person(
            firstName: firstName,
            lastName: lastName,
            nickname: nickname.trimmingCharacters(in: .whitespaces),
            notes: notes,
            birthdayDay: selectedDay,
            birthdayMonth: selectedMonth,
            birthdayYear: selectedYear ?? Calendar.current.component(.year, from: .now),
            photoData: croppedImage?.jpegData(compressionQuality: 0.9),
            notifyOnDay: notifyOnDay,
            notifyOneWeekBefore: notifyOneWeekBefore
        )
        modelContext.insert(person)
        for group in allGroups where selectedGroups.contains(group.id) {
            group.members.append(person)
        }
        onSaved?()
        dismiss()
    }
}
