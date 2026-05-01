import SwiftData
import SwiftUI

struct EventDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let eventID: PersistentIdentifier

    @State private var showEditSheet = false

    private var event: Event? {
        try? modelContext.model(for: eventID) as? Event
    }


    var body: some View {
        if let event {
            let daysUntil = event.daysUntilEvent
            List {
                Section {
                    VStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(event.color.opacity(0.18))
                                .frame(width: 112, height: 112)
                            Image(systemName: event.iconName)
                                .font(.system(size: 46, weight: .medium))
                                .foregroundStyle(event.color)
                        }

                        VStack(spacing: 4) {
                            Text(event.name)
                                .font(.system(.title, design: .rounded).weight(.bold))
                                .multilineTextAlignment(.center)

                            Text(event.formattedDate)
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSecondary)
                        }

                        VStack(spacing: 2) {
                            if daysUntil == 0 {
                                Text("Today")
                                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                                    .foregroundStyle(event.color)
                            } else {
                                HStack(alignment: .lastTextBaseline, spacing: 6) {
                                    Text("\(daysUntil)")
                                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                                        .monospacedDigit()
                                        .foregroundStyle(daysUntil <= 7 ? Theme.celebration : event.color)
                                    Text(daysUntil == 1 ? "day" : "days")
                                        .font(.system(.title3, design: .rounded).weight(.semibold))
                                        .foregroundStyle(Theme.textSecondary)
                                }
                            }
                            if let years = event.turnsYears {
                                Text(years == 1 ? "1 year anniversary" : "\(years) year anniversary")
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.textSecondary)
                            } else {
                                Text("until")
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                if !event.notes.isEmpty {
                    Section {
                        Text("Notes")
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    Section {
                        Text(event.notes)
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
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.surface)
            .navigationTitle(event.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") {
                        showEditSheet = true
                    }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                EditEventView(event: event)
            }
        } else {
            ContentUnavailableView("Event Not Found", systemImage: "calendar.badge.exclamationmark")
        }
    }
}
