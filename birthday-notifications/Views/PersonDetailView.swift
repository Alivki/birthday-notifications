import SwiftData
import SwiftUI

struct PersonDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let personID: PersistentIdentifier

    @State private var showEditSheet = false
    @State private var showAddGift = false
    @State private var selectedGift: GiftIdea?

    private var person: Person? {
        try? modelContext.model(for: personID) as? Person
    }

    var body: some View {
        if let person {
            List {
                // Header
                Section {
                    VStack(spacing: 12) {
                        PersonPhoto(person: person, size: 100)

                        Text(person.fullName)
                            .font(.title2.weight(.bold))

                        HStack(spacing: 8) {
                            Text("Turns \(person.turnsAge)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.pink)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(.pink.opacity(0.12), in: Capsule())

                            ForEach(person.groups) { group in
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(group.color)
                                        .frame(width: 8, height: 8)
                                    Text(group.name)
                                        .font(.caption.weight(.medium))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(group.color.opacity(0.12), in: Capsule())
                                .foregroundStyle(group.color)
                            }
                        }

                        HStack(spacing: 16) {
                            Label(person.formattedBirthday, systemImage: "calendar")
                            if person.daysUntilBirthday == 0 {
                                Text("🎂 Today")
                                    .fontWeight(.semibold)
                            } else {
                                Text("In \(person.daysUntilBirthday) days")
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)

                // Notes
                if !person.notes.isEmpty {
                    Section("Notes") {
                        Text(person.notes)
                            .foregroundStyle(.secondary)
                    }
                }

                // Gift Ideas
                Section {
                    ForEach(person.giftIdeas.sorted(by: { $0.createdAt > $1.createdAt })) { gift in
                        Button {
                            selectedGift = gift
                        } label: {
                            GiftIdeaRow(gift: gift)
                        }
                    }
                    .onDelete { offsets in
                        deleteGifts(offsets, person: person)
                    }

                    Button {
                        showAddGift = true
                    } label: {
                        Label("Add Gift Idea", systemImage: "plus")
                    }
                } header: {
                    Text("Gift Ideas")
                }
            }
            .navigationTitle(person.firstName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") {
                        showEditSheet = true
                    }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                EditPersonView(person: person)
            }
            .sheet(isPresented: $showAddGift) {
                AddGiftIdeaView(person: person)
            }
            .sheet(item: $selectedGift) { gift in
                GiftIdeaDetailView(gift: gift)
            }
        } else {
            ContentUnavailableView("Person Not Found", systemImage: "person.slash")
        }
    }

    private func deleteGifts(_ offsets: IndexSet, person: Person) {
        let sorted = person.giftIdeas.sorted(by: { $0.createdAt > $1.createdAt })
        for index in offsets {
            let gift = sorted[index]
            person.giftIdeas.removeAll { $0.id == gift.id }
            modelContext.delete(gift)
        }
    }
}

// MARK: - Gift Idea Row

struct GiftIdeaRow: View {
    let gift: GiftIdea

    var body: some View {
        HStack(spacing: 12) {
            if let data = gift.photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.blue.opacity(0.1))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "gift")
                            .foregroundStyle(.blue)
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(gift.title)
                        .font(.body)
                        .foregroundStyle(.black)
                        .strikethrough(gift.isPurchased)
                    if gift.isPurchased {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }

                if let price = gift.estimatedPrice {
                    Text("\(Int(price)) kr")
                        .font(.caption)
                        .foregroundStyle(.black)
                }

                if !gift.notes.isEmpty {
                    Text(gift.notes)
                        .font(.caption)
                        .foregroundStyle(.black)
                        .lineLimit(2)
                }
            }

            Spacer()

            if let urlString = gift.url, !urlString.isEmpty {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.black)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Gift Idea Detail View

struct GiftIdeaDetailView: View {
    let gift: GiftIdea
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Large image
                    if let data = gift.photoData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.blue.opacity(0.08))
                            .frame(height: 200)
                            .overlay(
                                Image(systemName: "gift.fill")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.blue.opacity(0.3))
                            )
                            .padding(.horizontal)
                    }

                    // Info
                    VStack(alignment: .leading, spacing: 16) {
                        // Title + purchased
                        HStack {
                            Text(gift.title)
                                .font(.title2.weight(.bold))
                                .strikethrough(gift.isPurchased)
                            if gift.isPurchased {
                                Text("Purchased")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.green)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(.green.opacity(0.12), in: Capsule())
                            }
                        }

                        // Price
                        if let price = gift.estimatedPrice {
                            HStack {
                                Image(systemName: "tag")
                                    .foregroundStyle(.secondary)
                                Text("\(Int(price)) kr")
                                    .font(.title3.weight(.medium))
                            }
                        }

                        // Link
                        if let urlString = gift.url, !urlString.isEmpty {
                            HStack {
                                Image(systemName: "link")
                                    .foregroundStyle(.blue)
                                Text(urlString)
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                                    .lineLimit(1)
                            }
                        }

                        // Notes
                        if !gift.notes.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Notes")
                                    .font(.headline)
                                Text(gift.notes)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Gift Idea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
