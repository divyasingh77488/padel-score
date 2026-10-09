public enum Team: String, Codable, CaseIterable, Sendable {
  case a = "A"
  case b = "B"

  public var other: Team { self == .a ? .b : .a }
}

/// How a game is decided from 40–40:
/// - advantage: a team must win two points in a row.
/// - golden: the next point wins the game.
/// - star: advantage is played at the first two deuces; at the third deuce the next point wins.
public enum DeuceRule: String, Codable, CaseIterable, Sendable {
  case advantage
  case golden
  case star
}

/// A value for each team.
public struct PerTeam<Value> {
  public var a: Value
  public var b: Value

  public init(a: Value, b: Value) {
    self.a = a
    self.b = b
  }

  public subscript(team: Team) -> Value {
    get { team == .a ? a : b }
    set {
      if team == .a { a = newValue } else { b = newValue }
    }
  }
}

extension PerTeam: Equatable where Value: Equatable {}
extension PerTeam: Codable where Value: Codable {}
extension PerTeam: Sendable where Value: Sendable {}

public struct MatchSetup: Codable, Equatable, Sendable {
  public var teamNames: PerTeam<String>
  public var firstServer: Team
  public var deuceRule: DeuceRule

  public init(teamNames: PerTeam<String>, firstServer: Team, deuceRule: DeuceRule) {
    self.teamNames = teamNames
    self.firstServer = firstServer
    self.deuceRule = deuceRule
  }
}

public struct CompletedSet: Equatable, Sendable {
  public var games: PerTeam<Int>
  /// Tiebreak points, present only when the set was decided by a tiebreak.
  public var tiebreak: PerTeam<Int>?

  public init(games: PerTeam<Int>, tiebreak: PerTeam<Int>? = nil) {
    self.games = games
    self.tiebreak = tiebreak
  }
}

public enum CurrentGame: Equatable, Sendable {
  /// Display strings: "0", "15", "30", "40" or "AD".
  case regular(PerTeam<String>)
  case tiebreak(PerTeam<Int>)
}

public struct MatchScore: Equatable, Sendable {
  public var completedSets: [CompletedSet]
  /// Games in the set being played.
  public var currentSet: PerTeam<Int>
  public var currentGame: CurrentGame
  public var server: Team
  /// True when the next point decides the game (golden or star point at 40–40).
  public var decidingPoint: Bool
  public var setsWon: PerTeam<Int>
  public var winner: Team?
}
