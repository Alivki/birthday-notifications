import SwiftData
import SwiftUI

struct EventDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let eventID: PersistentIdentifier

    @State private var showEditSheet = false

    private var event: Event? {
        try? modelContext.model(for: eventID) as? Event
    }

    private func pills(for event: Event, daysUntil: Int) -> [DetailPill] {
        var result: [DetailPill] = [
            DetailPill(title: daysUntilLabel(daysUntil), accent: event.color, filled: true)
        ]
        if let years = event.turnsYears {
            result.append(DetailPill(title: years == 1 ? "1 year" : "\(years) years", accent: event.color, filled: false))
        }
        return result
    }

    var body: some View {
        if let event {
            let daysUntil = event.daysUntilEvent
            List {
                Section {
                    DetailHeader(
                        title: event.name,
                        subtitle: event.formattedDate,
                        icon: {
                            ZStack {
                                Circle()
                                    .fill(event.color.opacity(0.15))
                                    .frame(width: 104, height: 104)
                                Image(systemName: event.iconName)
                                    .font(.system(size: 40))
                                    .foregroundStyle(event.color)
                            }
                        },
                        chips: { EmptyView() },
                        pills: pills(for: event, daysUntil: daysUntil)
                    )
                }
                .listRowBackground(Color.clear)

                if !event.notes.isEmpty {
                    Section("Notes") {
                        Text(event.notes)
                            .foregroundStyle(.secondary)
                    }
                }
            }
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
