import PhotosUI
import SwiftData
import SwiftUI

struct AddPersonView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \PersonGroup.name) private var allGroups: [PersonGroup]

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var notes = ""

    @State private var selectedYear: Int? = Calendar.current.component(.year, from: .now)
    @State private var selectedMonth = Calendar.current.component(.month, from: .now)
    @State private var selectedDay = Calendar.current.component(.day, from: .now)

    @State private var selectedGroups: Set<PersistentIdentifier> = []

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var rawUIImage: UIImage?
    @State private var croppedImage: UIImage?

    @State private var showDatePicker = true
    @State private var showCropper = false
    @State private var isEditingName = false

    @FocusState private var firstNameFocused: Bool
    @FocusState private var lastNameFocused: Bool

    private var currentYear: Int { Calendar.current.component(.year, from: .now) }

    private var hasName: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty ||
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                photoSection
                nameSection
                groupSection
                birthdaySection
                notesSection
            }
            .navigationTitle("Add Person")
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
            if isEditingName {
                TextField("First Name", text: $firstName)
                    .focused($firstNameFocused)
                    .onSubmit { lastNameFocused = true }
                TextField("Last Name", text: $lastName)
                    .focused($lastNameFocused)
                    .onSubmit { collapseNameIfNeeded() }
            } else if hasName {
                Button {
                    isEditingName = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        firstNameFocused = true
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text("\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces))
                            .foregroundStyle(.black)
                        Spacer()
                    }
                }
            } else {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isEditingName = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        firstNameFocused = true
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text("Name")
                            .foregroundStyle(.black)
                        Spacer()
                    }
                }
            }
        }
        .onChange(of: firstNameFocused) { collapseNameIfNeeded() }
        .onChange(of: lastNameFocused) { collapseNameIfNeeded() }
    }

    @ViewBuilder
    private var groupSection: some View {
        Section {
            NavigationLink {
                GroupSelectionView(selectedGroups: $selectedGroups)
            } label: {
                HStack {
                    Text("Group")
                        .foregroundStyle(.black)
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
            VStack(spacing: 12) {
                birthdayHeader
                if showDatePicker {
                    birthdayPickers
                }
                Divider()
                birthdayNext
            }
            .animation(.spring(duration: 0.4, bounce: 0.1), value: showDatePicker)
        }
    }

    @ViewBuilder
    private var birthdayHeader: some View {
        Button {
            showDatePicker.toggle()
        } label: {
            HStack {
                Text("Birthday")
                    .foregroundStyle(.black)
                Spacer()
                Text(shortBirthday)
                    .foregroundStyle(.blue)
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
                    .rotationEffect(.degrees(showDatePicker ? 0 : -90))
                    .foregroundStyle(.blue)
            }
        }
    }

    @ViewBuilder
    private var birthdayPickers: some View {
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
                    Text(Self.monthName(m)).tag(m)
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

    @ViewBuilder
    private var birthdayNext: some View {
        HStack {
            Text("Next")
            Spacer()
            if isBirthdayToday {
                Text("🎂 Today")
            } else {
                Text("\(daysUntilBirthday) days")
            }
        }
        .foregroundStyle(.secondary)
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

    private var isBirthdayToday: Bool {
        let cal = Calendar.current
        let today = Date()
        return cal.component(.month, from: today) == selectedMonth &&
               cal.component(.day, from: today) == selectedDay
    }

    private var shortBirthday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        let date = Calendar.current.date(from: DateComponents(year: 2000, month: selectedMonth, day: selectedDay))!
        return formatter.string(from: date)
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
        if selectedGroups.isEmpty { return "No" }
        let names = allGroups.filter { selectedGroups.contains($0.id) }.map(\.name)
        return names.joined(separator: ", ")
    }

    static func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        return formatter.monthSymbols[month - 1]
    }

    // MARK: - Actions

    private func collapseNameIfNeeded() {
        if !firstNameFocused && !lastNameFocused && isEditingName {
            withAnimation(.easeInOut(duration: 0.25)) {
                isEditingName = false
            }
        }
    }

    private func save() {
        let person = Person(
            firstName: firstName,
            lastName: lastName,
            notes: notes,
            birthdayDay: selectedDay,
            birthdayMonth: selectedMonth,
            birthdayYear: selectedYear ?? Calendar.current.component(.year, from: .now),
            photoData: croppedImage?.jpegData(compressionQuality: 0.9)
        )
        modelContext.insert(person)
        for group in allGroups where selectedGroups.contains(group.id) {
            group.members.append(person)
        }
        dismiss()
    }
}
