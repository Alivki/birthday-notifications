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
            let daysUntil = person.daysUntilBirthday
            List {
                // Header
                Section {
                    DetailHeader(
                        title: person.fullName,
                        subtitle: person.formattedBirthday,
                        icon: { PersonPhoto(person: person, size: 104) },
                        chips: {
                            if !person.groups.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 6) {
                                        ForEach(person.groups) { group in
                                            GroupChip(group: group)
                                        }
                                    }
                                    .padding(.horizontal, 1)
                                }
                            }
                        },
                        pills: [
                            DetailPill(title: daysUntilLabel(daysUntil), accent: .pink, filled: true),
                            DetailPill(title: "Turns \(person.turnsAge)", accent: .pink, filled: false),
                        ]
                    )
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
                    if person.giftIdeas.isEmpty {
                        Button {
                            showAddGift = true
                        } label: {
                            Label("Add a gift idea", systemImage: "plus")
                        }
                    } else {
                        ForEach(person.giftIdeas.sorted(by: { $0.createdAt > $1.createdAt })) { gift in
                            Button {
                                selectedGift = gift
                            } label: {
                                GiftIdeaRow(gift: gift)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { offsets in
                            deleteGifts(offsets, person: person)
                        }

                        Button {
                            showAddGift = true
                        } label: {
                            Label("Add another", systemImage: "plus")
                        }
                    }
                } header: {
                    Text("Gift ideas")
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
                HStack(spacing: 6) {
                    Text(gift.title)
                        .font(.body)
                        .foregroundStyle(gift.isPurchased ? .secondary : .primary)
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
                        .foregroundStyle(.secondary)
                }

                if !gift.notes.isEmpty {
                    Text(gift.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            if let urlString = gift.url, !urlString.isEmpty {
                Image(systemName: "link")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
                        HStack(alignment: .top, spacing: 8) {
                            Text(gift.title)
                                .font(.title2.weight(.bold))
                                .strikethrough(gift.isPurchased)
                                .foregroundStyle(gift.isPurchased ? .secondary : .primary)
                            Spacer(minLength: 0)
                            if gift.isPurchased {
                                CountdownPill(title: "Purchased", accent: .green, filled: true)
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
            .navigationTitle(gift.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
