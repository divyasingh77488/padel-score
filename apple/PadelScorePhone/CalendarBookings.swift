import EventKit
import PadelScoreKit
import UIKit

/// Upcoming court bookings from the iPhone's calendars (Playtomic and most clubs can add
/// bookings to the calendar). Nothing is read until the user asks, and nothing leaves the phone
/// except the booking attached to a match.
@MainActor
final class CalendarBookings: ObservableObject {
  enum Access {
    case notAsked
    case granted
    case denied
  }

  /// A calendar event that can be attached to a match.
  struct Event: Identifiable, Equatable {
    let id: String
    let booking: Booking
    let looksLikePadel: Bool
  }

  /// How far ahead to look.
  private static let lookAhead: TimeInterval = 14 * 24 * 3600
  /// Bookings that started up to this long ago still count (you may set up the match on court).
  private static let lookBack: TimeInterval = 2 * 3600

  @Published private(set) var access: Access
  /// Upcoming events, soonest first.
  @Published private(set) var events: [Event] = []

  private let store = EKEventStore()

  init() {
    switch EKEventStore.authorizationStatus(for: .event) {
    case .fullAccess: access = .granted
    case .notDetermined: access = .notAsked
    default: access = .denied
    }
  }

  /// Asks for access the first time, then reads upcoming events.
  func load() async {
    if access == .notAsked {
      let granted = (try? await store.requestFullAccessToEvents()) ?? false
      access = granted ? .granted : .denied
    }
    guard access == .granted else { return }
    let now = Date()
    let predicate = store.predicateForEvents(
      withStart: now.addingTimeInterval(-Self.lookBack),
      end: now.addingTimeInterval(Self.lookAhead), calendars: nil)
    events = store.events(matching: predicate)
      .filter { !$0.isAllDay }
      .sorted { $0.startDate < $1.startDate }
      .map { event in
        let title = event.title ?? "Event"
        return Event(
          id: event.calendarItemIdentifier + "\(event.startDate.timeIntervalSince1970)",
          booking: Booking(title: title, place: event.location, start: event.startDate),
          looksLikePadel: Booking.looksLikePadel(
            title: event.title, location: event.location, notes: event.notes))
      }
  }

  /// Opens this app's page in Settings, where calendar access can be turned back on.
  func openSettings() {
    if let url = URL(string: UIApplication.openSettingsURLString) {
      UIApplication.shared.open(url)
    }
  }
}
