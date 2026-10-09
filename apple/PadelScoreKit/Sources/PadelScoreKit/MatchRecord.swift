import Foundation

/// A match set up on the phone, waiting to be started on the watch (or the phone).
public struct PlannedMatch: Codable, Equatable, Identifiable, Sendable {
  public var id: UUID
  public var setup: MatchSetup
  public var createdAt: Date

  public init(id: UUID = UUID(), setup: MatchSetup, createdAt: Date = Date()) {
    self.id = id
    self.setup = setup
    self.createdAt = createdAt
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

  public init(
    id: UUID = UUID(), setup: MatchSetup, points: [Team] = [], startedAt: Date = Date(),
    finishedAt: Date? = nil
  ) {
    self.id = id
    self.setup = setup
    self.points = points
    self.startedAt = startedAt
    self.finishedAt = finishedAt
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
