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
            List {
                Section {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(event.color.opacity(0.15))
                                .frame(width: 100, height: 100)
                            Image(systemName: event.iconName)
                                .font(.system(size: 38))
                                .foregroundStyle(event.color)
                        }

                        Text(event.name)
                            .font(.title2.weight(.bold))

                        if let years = event.turnsYears {
                            Text("\(years) years")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(event.color)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(event.color.opacity(0.12), in: Capsule())
                        }

                        HStack(spacing: 16) {
                            Label(event.formattedDate, systemImage: "calendar")
                            if event.daysUntilEvent == 0 {
                                Text("Today!")
                                    .fontWeight(.semibold)
                            } else {
                                Text("In \(event.daysUntilEvent) days")
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
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
