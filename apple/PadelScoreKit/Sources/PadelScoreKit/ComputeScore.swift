// Port of src/scoring/computeScore.ts. Keep the two in step: the same tests cover both.

private let setsToWin = 2
private let gamesPerSet = 6
private let tiebreakPoints = 7
private let gameLabels = ["0", "15", "30", "40"]

/// At which deuce (1st, 2nd, ...) the next point decides the game, per rule.
private func decidingDeuce(_ rule: DeuceRule) -> Int {
  switch rule {
  case .advantage: return Int.max
  case .golden: return 1
  case .star: return 3
  }
}

private let zero = PerTeam(a: 0, b: 0)

/// Display for a regular (non-tiebreak) game from raw point counts.
private func regularDisplay(_ p: PerTeam<Int>) -> PerTeam<String> {
  if p.a >= 3 && p.b >= 3 {
    if p.a == p.b { return PerTeam(a: "40", b: "40") }
    return p.a > p.b ? PerTeam(a: "AD", b: "40") : PerTeam(a: "40", b: "AD")
  }
  return PerTeam(a: gameLabels[p.a], b: gameLabels[p.b])
}

/// Whether `p` is a won game/tiebreak for `team`: at least `target` points and a 2-point lead.
private func hasWon(_ p: PerTeam<Int>, _ team: Team, _ target: Int) -> Bool {
  p[team] >= target && p[team] - p[team.other] >= 2
}

/// Tiebreak server for the point about to be played, given how many tiebreak points have been
/// played. The first server serves 1 point, then teams alternate every 2.
private func tiebreakServer(_ firstServer: Team, played: Int) -> Team {
  if played == 0 { return firstServer }
  return ((played - 1) / 2) % 2 == 0 ? firstServer.other : firstServer
}

/// Replays the points of a match and returns everything the screen shows.
/// Points after the match has been won are ignored.
public func computeScore(_ setup: MatchSetup, _ points: [Team]) -> MatchScore {
  var completedSets: [CompletedSet] = []
  var setsWon = zero
  var games = zero
  var gamePoints = zero
  // How many times the current game has reached 40–40.
  var deuces = 0
  var inTiebreak = false
  // Server of the current regular game, or the first server of the current tiebreak.
  var gameServer = setup.firstServer
  var winner: Team?

  func winSet(_ team: Team, tiebreak: PerTeam<Int>? = nil) {
    completedSets.append(CompletedSet(games: games, tiebreak: tiebreak))
    setsWon[team] += 1
    games = zero
    if setsWon[team] >= setsToWin { winner = team }
  }

  func isDecidingPoint() -> Bool {
    !inTiebreak && gamePoints.a == gamePoints.b && deuces >= decidingDeuce(setup.deuceRule)
  }

  for team in points {
    if winner != nil { break }
    let decides = isDecidingPoint()
    gamePoints[team] += 1

    if inTiebreak {
      if hasWon(gamePoints, team, tiebreakPoints) {
        games[team] += 1
        winSet(team, tiebreak: gamePoints)
        gamePoints = zero
        inTiebreak = false
        // The team that received first in the tiebreak serves the next set.
        gameServer = gameServer.other
      }
      continue
    }

    if gamePoints.a >= 3 && gamePoints.a == gamePoints.b { deuces += 1 }

    if decides || hasWon(gamePoints, team, 4) {
      games[team] += 1
      gamePoints = zero
      deuces = 0
      gameServer = gameServer.other
      if hasWon(games, team, gamesPerSet) {
        winSet(team)
      } else if games.a == gamesPerSet && games.b == gamesPerSet {
        inTiebreak = true
      }
    }
  }

  let currentGame: CurrentGame =
    inTiebreak ? .tiebreak(gamePoints) : .regular(regularDisplay(gamePoints))
  let server =
    inTiebreak ? tiebreakServer(gameServer, played: gamePoints.a + gamePoints.b) : gameServer

  return MatchScore(
    completedSets: completedSets,
    currentSet: games,
    currentGame: currentGame,
    server: server,
    decidingPoint: winner == nil && isDecidingPoint(),
    setsWon: setsWon,
    winner: winner
  )
}

/// Formats completed sets from `team`'s point of view, e.g. `6–4  3–6  7–6(5)`.
/// The bracketed number is the tiebreak loser's points.
public func formatSets(_ sets: [CompletedSet], from team: Team) -> String {
  sets.map { (set: CompletedSet) -> String in
    let base = "\(set.games[team])–\(set.games[team.other])"
    guard let tiebreak = set.tiebreak else { return base }
    return "\(base)(\(min(tiebreak.a, tiebreak.b)))"
  }
  .joined(separator: "  ")
}
