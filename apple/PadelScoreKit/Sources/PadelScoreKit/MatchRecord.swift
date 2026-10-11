import Foundation

/// A court booking the match was set up from, taken from the iPhone's calendar.
public struct Booking: Codable, Equatable, Sendable {
  /// The calendar event's title, e.g. "Padel at Club X".
  public var title: String
  /// The event's location (usually the club), if it has one.
  public var place: String?
  public var start: Date

  public init(title: String, place: String? = nil, start: Date) {
    self.title = title
    self.place = place
    self.start = start
  }

  /// The club if known, otherwise the event title.
  public var placeOrTitle: String {
    if let place, !place.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      // Only the first line: calendar locations often include the full address.
      return place.split(whereSeparator: \.isNewline).first.map(String.init) ?? place
    }
    return title
  }

  /// Words that mark a calendar event as a padel booking (Playtomic and most clubs use one).
  public static let keywords = ["padel", "pádel", "playtomic"]

  /// Whether a calendar event looks like a padel booking.
  public static func looksLikePadel(title: String?, location: String?, notes: String?) -> Bool {
    let text = [title, location, notes].compactMap { $0 }.joined(separator: " ")
      .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    return keywords.contains { text.contains($0.folding(options: .diacriticInsensitive, locale: nil)) }
  }
}

/// A match set up on the phone, waiting to be started on the watch (or the phone).
public struct PlannedMatch: Codable, Equatable, Identifiable, Sendable {
  public var id: UUID
  public var setup: MatchSetup
  public var createdAt: Date
  public var booking: Booking?

  public init(
    id: UUID = UUID(), setup: MatchSetup, createdAt: Date = Date(), booking: Booking? = nil
  ) {
    self.id = id
    self.setup = setup
    self.createdAt = createdAt
    self.booking = booking
  }
}

/// A started match: its setup and the winner of each point. The score is always recomputed from
/// the points, so undo and sync can never disagree with it.
public struct MatchRecord: Codable, Equatable, Identifiable, Sendable {
  public var id: UUID
  public var setup: MatchSetup
  public var points: [Team]
  public var startedAt: Date
  /// Set when the match is put into history.
  public var finishedAt: Date?
  /// The court booking it was set up from, if any.
  public var booking: Booking?

  public init(
    id: UUID = UUID(), setup: MatchSetup, points: [Team] = [], startedAt: Date = Date(),
    finishedAt: Date? = nil, booking: Booking? = nil
  ) {
    self.id = id
    self.setup = setup
    self.points = points
    self.startedAt = startedAt
    self.finishedAt = finishedAt
    self.booking = booking
  }

  public var score: MatchScore { computeScore(setup, points) }
}

public enum MatchHistory {
  public static let maxEntries = 200

  /// Adds a match to the front of the history, replacing any entry with the same id. Matches
  /// ended early are kept too (games are often stopped when the court time runs out); a match
  /// with no points played is ignored.
  public static func adding(_ record: MatchRecord, to history: [MatchRecord]) -> [MatchRecord] {
    guard !record.points.isEmpty else { return history }
    var entry = record
    if entry.finishedAt == nil { entry.finishedAt = Date() }
    let rest = history.filter { $0.id != record.id }
    return Array(([entry] + rest).prefix(maxEntries))
  }
}

/// JSON coding used for storage and for messages between the phone and the watch.
public enum SyncCoding {
  public static func encode<T: Encodable>(_ value: T) -> Data {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    return (try? encoder.encode(value)) ?? Data()
  }

  public static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
    guard let data else { return nil }
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try? decoder.decode(type, from: data)
  }
}
