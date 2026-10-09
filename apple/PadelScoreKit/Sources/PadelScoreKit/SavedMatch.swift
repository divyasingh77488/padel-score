import Foundation

/// A match as stored on the device: the setup plus the winner of each point.
public struct SavedMatch: Codable, Equatable, Sendable {
  public static let currentVersion = 1

  public var version: Int
  public var setup: MatchSetup
  public var points: [Team]

  public init(setup: MatchSetup, points: [Team]) {
    self.version = Self.currentVersion
    self.setup = setup
    self.points = points
  }

  public func encoded() -> Data? {
    try? JSONEncoder().encode(self)
  }

  /// Decodes stored data. Returns nil when it is missing, unreadable or from another version.
  public static func decode(_ data: Data?) -> SavedMatch? {
    guard let data, let match = try? JSONDecoder().decode(SavedMatch.self, from: data),
      match.version == currentVersion
    else { return nil }
    return match
  }
}
