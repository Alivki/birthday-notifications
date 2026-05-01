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
            let secondaryTitle: String = {
                if let years = event.turnsYears {
                    return years == 1 ? "1 year anniversary" : "\(years) year anniversary"
                }
                return event.formattedDate
            }()
            let secondaryDetail: String = event.turnsYears != nil
                ? event.nextOccurrenceWeekdayAndDate
                : event.nextOccurrenceWeekdayAndDate

            List {
                Section {
                    VStack(alignment: .leading, spacing: 20) {
                        // Identity row: icon + name
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(event.color.opacity(0.18))
                                    .frame(width: 76, height: 76)
                                Image(systemName: event.iconName)
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundStyle(event.color)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(event.name)
                                    .font(.title2.weight(.bold))
                                    .lineLimit(2)
                                Text(event.formattedDate)
                                    .font(.footnote.weight(.medium))
                                    .foregroundStyle(Theme.textSecondary)
                            }

                            Spacer(minLength: 0)
                        }

                        StatBlock(
                            primaryValue: daysUntil == 0 ? "TODAY" : "\(daysUntil)",
                            primaryLabel: daysUntil == 0 ? "EVENT" : "DAYS LEFT",
                            primaryColor: daysUntil == 0 || daysUntil <= 7 ? Theme.celebration : event.color,
                            primaryIsCompact: daysUntil == 0,
                            secondaryTitle: secondaryTitle,
                            secondaryDetail: secondaryDetail,
                            secondaryTitleIcon: event.turnsYears != nil ? "sparkles" : event.iconName,
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

                if !event.notes.isEmpty {
                    Section {
                        Text("Notes")
                            .font(.system(.title3).weight(.bold))
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
