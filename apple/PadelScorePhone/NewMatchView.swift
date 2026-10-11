import PadelScoreKit
import SwiftUI

struct NewMatchView: View {
  @ObservedObject var store: PhoneStore
  @Environment(\.dismiss) private var dismiss

  @State private var nameA = ""
  @State private var nameB = ""
  @State private var firstServer: Team = .a
  @State private var deuceRule: DeuceRule = .golden
  @State private var loaded = false
  @StateObject private var calendar = CalendarBookings()
  @State private var bookingId: String?
  @State private var showAllEvents = false
  @State private var autoPicked = false

  var body: some View {
    NavigationStack {
      Form {
        Section {
          bookingRows
        } header: {
          Text("Court booking")
        } footer: {
          Text(
            calendar.access == .granted
              ? "Tap a booking to add it to the match. Its time and club show on the watch and in History."
              : "Finds your padel bookings (for example from Playtomic) in your calendar for the next 2 weeks. Nothing leaves your phone."
          )
        }

        Section("Teams") {
          TextField("Team A", text: $nameA)
            .foregroundStyle(Theme.color(.a))
          TextField("Team B", text: $nameB)
            .foregroundStyle(Theme.color(.b))
        }

        Section("Serves first") {
          Picker("Serves first", selection: $firstServer) {
            Text(name(.a)).tag(Team.a)
            Text(name(.b)).tag(Team.b)
          }
          .pickerStyle(.segmented)
        }

        Section("At 40–40") {
          Picker("At 40–40", selection: $deuceRule) {
            ForEach(DeuceRule.allCases, id: \.self) { rule in
              Text(rule.shortLabel).tag(rule)
            }
          }
          .pickerStyle(.segmented)
          DisclosureGroup {
            ForEach(DeuceRule.allCases, id: \.self) { rule in
              VStack(alignment: .leading, spacing: 2) {
                Text(rule.label)
                  .font(.subheadline.weight(.semibold))
                  .foregroundStyle(rule == deuceRule ? Theme.accent : .primary)
                Text(rule.explanation)
                  .font(.footnote)
                  .foregroundStyle(.secondary)
              }
            }
          } label: {
            Label("What do these mean?", systemImage: "info.circle")
          }
        }

        Section {
          Button {
            store.sendToWatch(setup, booking: selectedBooking)
            dismiss()
          } label: {
            Label("Send to watch", systemImage: "applewatch")
              .font(.headline)
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.borderedProminent)
          .tint(Theme.accent)
          .foregroundStyle(.black)
          .listRowBackground(Color.clear)

          Button {
            store.playOnPhone(setup, booking: selectedBooking)
            dismiss()
          } label: {
            Text("Play on phone now")
              .frame(maxWidth: .infinity)
          }
          .listRowBackground(Color.clear)
        }
      }
      .navigationTitle("New match")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
      }
      .onAppear {
        guard !loaded else { return }
        loaded = true
        let last = store.lastSetup
        nameA = last.teamNames.a
        nameB = last.teamNames.b
        firstServer = last.firstServer
        deuceRule = last.deuceRule
      }
      .task {
        if calendar.access == .granted { await loadBookings() }
      }
    }
  }

  @ViewBuilder private var bookingRows: some View {
    switch calendar.access {
    case .notAsked:
      Button {
        Task { await loadBookings() }
      } label: {
        Label("Find my bookings in Calendar", systemImage: "calendar.badge.plus")
      }
    case .denied:
      Text("Calendar access is off for Padel Battle.")
        .foregroundStyle(.secondary)
      Button("Turn it on in Settings") { calendar.openSettings() }
    case .granted:
      let shown = showAllEvents ? calendar.events : calendar.events.filter(\.looksLikePadel)
      if shown.isEmpty {
        Text(showAllEvents ? "No events in the next 2 weeks." : "No padel bookings in the next 2 weeks.")
          .foregroundStyle(.secondary)
      }
      ForEach(shown) { event in
        Button {
          bookingId = bookingId == event.id ? nil : event.id
        } label: {
          HStack {
            VStack(alignment: .leading, spacing: 2) {
              Text(event.booking.title)
                .foregroundStyle(.primary)
              Text(bookingDetail(event.booking))
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            if bookingId == event.id {
              Image(systemName: "checkmark")
                .foregroundStyle(Theme.accent)
            }
          }
        }
      }
      Toggle("Show all events", isOn: $showAllEvents)
    }
  }

  private func bookingDetail(_ booking: Booking) -> String {
    let when = Booking.dayAndTime(booking.start)
    return booking.placeOrTitle == booking.title ? when : "\(when) · \(booking.placeOrTitle)"
  }

  private var selectedBooking: Booking? {
    calendar.events.first { $0.id == bookingId }?.booking
  }

  /// Reads the calendar and, the first time, picks the next padel booking within a day.
  private func loadBookings() async {
    await calendar.load()
    guard !autoPicked else { return }
    autoPicked = true
    let soon = Date().addingTimeInterval(24 * 3600)
    if let next = calendar.events.first(where: { $0.looksLikePadel && $0.booking.start < soon }) {
      bookingId = next.id
    }
  }

  private var setup: MatchSetup {
    MatchSetup(
      teamNames: PerTeam(a: name(.a), b: name(.b)), firstServer: firstServer, deuceRule: deuceRule)
  }

  private func name(_ team: Team) -> String {
    let typed = (team == .a ? nameA : nameB).trimmingCharacters(in: .whitespaces)
    return typed.isEmpty ? (team == .a ? "Team A" : "Team B") : typed
  }
}
