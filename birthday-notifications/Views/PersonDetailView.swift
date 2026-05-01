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
            let countdownColor: Color = daysUntil <= 7 ? Theme.celebration : Theme.brand
            let nicknameDistinct = !person.nickname.trimmingCharacters(in: .whitespaces).isEmpty
                && person.nickname != person.fullName

            List {
                // Header — asymmetric identity row + hero countdown + chips.
                // Single left-aligned column establishes the screen's spine.
                Section {
                    VStack(alignment: .leading, spacing: 20) {
                        // Identity: photo + name + meta + group chips
                        HStack(alignment: .top, spacing: 16) {
                            PersonPhoto(person: person, size: 76)

                            VStack(alignment: .leading, spacing: 6) {
                                Text(person.fullName)
                                    .font(.title2.weight(.bold))
                                    .lineLimit(2)
                                if nicknameDistinct {
                                    Text("\u{201C}\(person.nickname)\u{201D}")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(Theme.brand)
                                }
                                Text(person.formattedBirthday)
                                    .font(.footnote.weight(.medium))
                                    .foregroundStyle(Theme.textSecondary)
                                if !person.groups.isEmpty {
                                    HStack(spacing: 6) {
                                        ForEach(person.groups) { group in
                                            GroupChip(group: group)
                                        }
                                    }
                                    .padding(.top, 2)
                                }
                            }

                            Spacer(minLength: 0)
                        }

                        // Stat block: anchor + iconified secondary info
                        StatBlock(
                            primaryValue: daysUntil == 0 ? "TODAY" : "\(daysUntil)",
                            primaryLabel: daysUntil == 0 ? "BIRTHDAY" : "DAYS LEFT",
                            primaryColor: daysUntil == 0 || daysUntil <= 7 ? Theme.celebration : Theme.brand,
                            primaryIsCompact: daysUntil == 0,
                            secondaryTitle: "Turning \(person.turnsAge)",
                            secondaryDetail: person.nextBirthdayWeekdayAndDate,
                            secondaryTitleIcon: "birthday.cake.fill",
                            secondaryDetailIcon: "calendar",
                            tinted: daysUntil == 0
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                // Notes
                if !person.notes.isEmpty {
                    sectionTitle("Notes")
                    Section {
                        Text(person.notes)
                            .foregroundStyle(.primary)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                                    .fill(Theme.card)
                            )
                            .cardShadow()
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }

                // Gift Ideas
                sectionTitle("Gift ideas")
                Section {
                    if person.giftIdeas.isEmpty {
                        Button {
                            showAddGift = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(Theme.brand)
                                Text("Add a gift idea")
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                                    .fill(Theme.card)
                            )
                            .cardShadow()
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(person.giftIdeas.sorted(by: { $0.createdAt > $1.createdAt })) { gift in
                            Button {
                                selectedGift = gift
                            } label: {
                                GiftIdeaRow(gift: gift)
                                    .padding(14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                                            .fill(Theme.card)
                                    )
                                    .cardShadow()
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        .onDelete { offsets in
                            deleteGifts(offsets, person: person)
                        }

                        Button {
                            showAddGift = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(Theme.brand)
                                Text("Add another")
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                                    .fill(Theme.card)
                            )
                            .cardShadow()
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.surface)
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

    @ViewBuilder
    private func sectionTitle(_ title: String) -> some View {
        Section {
            Text(title)
                .font(.system(.title3).weight(.bold))
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
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
                    .fill(Theme.brand.opacity(0.10))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "gift")
                            .foregroundStyle(Theme.brand)
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
                            .fill(Theme.brand.opacity(0.08))
                            .frame(height: 200)
                            .overlay(
                                Image(systemName: "gift.fill")
                                    .font(.system(size: 48))
                                    .foregroundStyle(Theme.brand.opacity(0.3))
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
                                    .foregroundStyle(Theme.brand)
                                Text(urlString)
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.brand)
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
