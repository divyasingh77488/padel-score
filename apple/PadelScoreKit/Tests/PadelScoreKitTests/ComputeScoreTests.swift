import XCTest

@testable import PadelScoreKit

// Port of src/scoring/computeScore.test.ts and format.test.ts.

private let setup = MatchSetup(
  teamNames: PerTeam(a: "Team A", b: "Team B"), firstServer: .a, deuceRule: .advantage)

private func rep(_ team: Team, _ n: Int) -> [Team] { Array(repeating: team, count: n) }
/// Points for one game won to love by `team`.
private func game(_ team: Team) -> [Team] { rep(team, 4) }
/// Points for `n` games won to love by `team`.
private func games(_ team: Team, _ n: Int) -> [Team] { (0..<n).flatMap { _ in game(team) } }
/// A 6–0 set for `team`.
private func set(_ team: Team) -> [Team] { games(team, 6) }
/// Alternate games until 6–6 (A, B, A, B, ...).
private func toSixAll() -> [Team] { (0..<12).flatMap { game($0 % 2 == 0 ? .a : .b) } }

private func pt(_ a: Int, _ b: Int) -> PerTeam<Int> { PerTeam(a: a, b: b) }
private func regular(_ a: String, _ b: String) -> CurrentGame { .regular(PerTeam(a: a, b: b)) }
private func tiebreak(_ a: Int, _ b: Int) -> CurrentGame { .tiebreak(pt(a, b)) }
private func sets(_ s: String) -> [Team] { s.map { $0 == "A" ? .a : .b } }

final class RegularGameTests: XCTestCase {
  func testStartsAtLove() {
    let s = computeScore(setup, [])
    XCTAssertEqual(s.currentGame, regular("0", "0"))
    XCTAssertEqual(s.currentSet, pt(0, 0))
    XCTAssertEqual(s.completedSets, [])
    XCTAssertEqual(s.setsWon, pt(0, 0))
    XCTAssertNil(s.winner)
  }

  func testCounts15_30_40() {
    XCTAssertEqual(computeScore(setup, [.a]).currentGame, regular("15", "0"))
    XCTAssertEqual(computeScore(setup, sets("ABA")).currentGame, regular("30", "15"))
    XCTAssertEqual(computeScore(setup, sets("AAABB")).currentGame, regular("40", "30"))
  }

  func testAwardsGameOnFourthPoint() {
    let s = computeScore(setup, game(.b))
    XCTAssertEqual(s.currentSet, pt(0, 1))
    XCTAssertEqual(s.currentGame, regular("0", "0"))
  }

  func testWinsFrom40_30() {
    XCTAssertEqual(computeScore(setup, sets("AAABBA")).currentSet, pt(1, 0))
  }
}

final class DeuceTests: XCTestCase {
  let deuce = sets("AAABBB")

  func testDeuceShows40_40() {
    XCTAssertEqual(computeScore(setup, deuce).currentGame, regular("40", "40"))
  }

  func testAdvantageAndBackToDeuce() {
    XCTAssertEqual(computeScore(setup, deuce + [.a]).currentGame, regular("AD", "40"))
    XCTAssertEqual(computeScore(setup, deuce + sets("AB")).currentGame, regular("40", "40"))
    XCTAssertEqual(computeScore(setup, deuce + sets("ABB")).currentGame, regular("40", "AD"))
  }

  func testNeedsTwoInARowFromDeuce() {
    let s = computeScore(setup, deuce + sets("ABBAABBB"))
    XCTAssertEqual(s.currentSet, pt(0, 1))
    XCTAssertEqual(s.currentGame, regular("0", "0"))
  }
}

final class SetTests: XCTestCase {
  func testWinsSet6_4() {
    let s = computeScore(setup, games(.a, 4) + games(.b, 4) + games(.a, 2))
    XCTAssertEqual(s.completedSets, [CompletedSet(games: pt(6, 4))])
    XCTAssertEqual(s.currentSet, pt(0, 0))
    XCTAssertEqual(s.setsWon, pt(1, 0))
  }

  func testDoesNotEndAt6_5() {
    let s = computeScore(setup, games(.a, 5) + games(.b, 5) + game(.a))
    XCTAssertEqual(s.completedSets, [])
    XCTAssertEqual(s.currentSet, pt(6, 5))
    XCTAssertEqual(s.currentGame, regular("0", "0"))
  }

  func testWinsSet7_5() {
    let s = computeScore(setup, games(.a, 5) + games(.b, 5) + games(.a, 2))
    XCTAssertEqual(s.completedSets, [CompletedSet(games: pt(7, 5))])
    XCTAssertEqual(s.setsWon, pt(1, 0))
  }

  func testTiebreakAt6_6() {
    let s = computeScore(setup, toSixAll())
    XCTAssertEqual(s.currentSet, pt(6, 6))
    XCTAssertEqual(s.currentGame, tiebreak(0, 0))
  }
}

final class TiebreakTests: XCTestCase {
  func testCountsPlainNumbers() {
    XCTAssertEqual(computeScore(setup, toSixAll() + sets("AAB")).currentGame, tiebreak(2, 1))
  }

  func testWinsTiebreak7_5() {
    let s = computeScore(setup, toSixAll() + rep(.a, 5) + rep(.b, 5) + sets("AA"))
    XCTAssertEqual(s.completedSets, [CompletedSet(games: pt(7, 6), tiebreak: pt(7, 5))])
    XCTAssertEqual(s.currentSet, pt(0, 0))
    XCTAssertEqual(s.currentGame, regular("0", "0"))
    XCTAssertEqual(s.setsWon, pt(1, 0))
  }

  func testDoesNotEndAt7_6() {
    let s = computeScore(setup, toSixAll() + rep(.a, 6) + rep(.b, 6) + [.a])
    XCTAssertEqual(s.currentGame, tiebreak(7, 6))
    XCTAssertEqual(s.completedSets, [])
  }

  func testWinsTiebreak10_8() {
    let tb = rep(.a, 6) + rep(.b, 6) + sets("ABABBB")
    let s = computeScore(setup, toSixAll() + tb)
    XCTAssertEqual(s.completedSets, [CompletedSet(games: pt(6, 7), tiebreak: pt(8, 10))])
    XCTAssertEqual(s.setsWon, pt(0, 1))
  }
}

final class ServeTests: XCTestCase {
  func testStartsWithChosenServer() {
    XCTAssertEqual(computeScore(setup, []).server, .a)
    var b = setup
    b.firstServer = .b
    XCTAssertEqual(computeScore(b, []).server, .b)
  }

  func testStaysWithServerDuringGame() {
    XCTAssertEqual(computeScore(setup, sets("BBA")).server, .a)
  }

  func testAlternatesEveryGame() {
    XCTAssertEqual(computeScore(setup, games(.a, 1)).server, .b)
    XCTAssertEqual(computeScore(setup, games(.a, 2)).server, .a)
    XCTAssertEqual(computeScore(setup, games(.b, 3)).server, .b)
  }

  func testKeepsAlternatingAcrossSets() {
    XCTAssertEqual(computeScore(setup, set(.a)).server, .a)
    XCTAssertEqual(computeScore(setup, games(.a, 4) + games(.b, 4) + games(.a, 2)).server, .a)
    XCTAssertEqual(computeScore(setup, games(.a, 5) + games(.b, 5) + games(.a, 2)).server, .a)
  }

  func testTiebreakRotation() {
    let base = toSixAll()
    let serverAfter = { (n: Int) -> Team in
      computeScore(setup, base + rep(.a, min(n, 3)) + rep(.b, max(0, n - 3))).server
    }
    XCTAssertEqual((0...8).map(serverAfter), [.a, .b, .b, .a, .a, .b, .b, .a, .a])
  }

  func testTeamDueToServeStartsTiebreak() {
    var b = setup
    b.firstServer = .b
    XCTAssertEqual(computeScore(b, toSixAll()).server, .b)
  }

  func testNextSetServedByTiebreakReceiver() {
    let pts = toSixAll() + rep(.a, 7)
    XCTAssertEqual(computeScore(setup, pts).server, .b)
    var b = setup
    b.firstServer = .b
    XCTAssertEqual(computeScore(b, pts).server, .a)
  }
}

final class MatchEndTests: XCTestCase {
  func testEndsAtTwoSets() {
    let s = computeScore(setup, set(.a) + set(.a))
    XCTAssertEqual(s.winner, .a)
    XCTAssertEqual(s.setsWon, pt(2, 0))
    XCTAssertEqual(s.completedSets, [CompletedSet(games: pt(6, 0)), CompletedSet(games: pt(6, 0))])
  }

  func testThirdSetAtOneSetAll() {
    let s = computeScore(setup, set(.a) + set(.b))
    XCTAssertNil(s.winner)
    XCTAssertEqual(s.setsWon, pt(1, 1))
    XCTAssertEqual(computeScore(setup, set(.a) + set(.b) + set(.b)).winner, .b)
  }

  func testWonWithFinalSetTiebreak() {
    let s = computeScore(setup, set(.a) + set(.b) + toSixAll() + rep(.b, 7))
    XCTAssertEqual(s.winner, .b)
    XCTAssertEqual(s.completedSets[2], CompletedSet(games: pt(6, 7), tiebreak: pt(0, 7)))
  }

  func testIgnoresPointsAfterMatch() {
    let finished = set(.a) + set(.a)
    XCTAssertEqual(computeScore(setup, finished + sets("BBB")), computeScore(setup, finished))
  }
}

final class UndoTests: XCTestCase {
  func testBackAcrossGameBoundary() {
    let s = computeScore(setup, Array((game(.a) + game(.b)).dropLast()))
    XCTAssertEqual(s.currentSet, pt(1, 0))
    XCTAssertEqual(s.currentGame, regular("0", "40"))
    XCTAssertEqual(s.server, .b)
  }

  func testBackAcrossSetBoundary() {
    let s = computeScore(setup, Array(set(.a).dropLast()))
    XCTAssertEqual(s.completedSets, [])
    XCTAssertEqual(s.currentSet, pt(5, 0))
    XCTAssertEqual(s.currentGame, regular("40", "0"))
  }

  func testReopensFinishedMatch() {
    let s = computeScore(setup, Array((set(.a) + set(.a)).dropLast()))
    XCTAssertNil(s.winner)
    XCTAssertEqual(s.setsWon, pt(1, 0))
  }

  func testBackIntoFinishedTiebreak() {
    let s = computeScore(setup, Array((toSixAll() + rep(.a, 7)).dropLast()))
    XCTAssertEqual(s.currentGame, tiebreak(6, 0))
    XCTAssertEqual(s.completedSets, [])
  }
}

final class DeuceRuleTests: XCTestCase {
  let deuce = sets("AAABBB")
  var golden: MatchSetup {
    var s = setup
    s.deuceRule = .golden
    return s
  }
  var star: MatchSetup {
    var s = setup
    s.deuceRule = .star
    return s
  }

  func testAdvantageNeverDeciding() {
    XCTAssertFalse(computeScore(setup, deuce + sets("ABBAAB")).decidingPoint)
  }

  func testGoldenPointWinsAfterDeuce() {
    XCTAssertFalse(computeScore(golden, sets("AAB")).decidingPoint)
    let atDeuce = computeScore(golden, deuce)
    XCTAssertEqual(atDeuce.currentGame, regular("40", "40"))
    XCTAssertTrue(atDeuce.decidingPoint)
    let s = computeScore(golden, deuce + [.b])
    XCTAssertEqual(s.currentSet, pt(0, 1))
    XCTAssertFalse(s.decidingPoint)
    XCTAssertEqual(s.server, .b)
  }

  func testGoldenPointNormalWinFrom40_30() {
    XCTAssertEqual(computeScore(golden, sets("AAABBA")).currentSet, pt(1, 0))
  }

  func testStarPointThirdDeuceDecides() {
    XCTAssertFalse(computeScore(star, deuce).decidingPoint)
    XCTAssertEqual(computeScore(star, deuce + [.a]).currentGame, regular("AD", "40"))
    let second = deuce + sets("AB")
    XCTAssertFalse(computeScore(star, second).decidingPoint)
    XCTAssertEqual(computeScore(star, second + [.b]).currentGame, regular("40", "AD"))
    let third = second + sets("BA")
    let s = computeScore(star, third)
    XCTAssertEqual(s.currentGame, regular("40", "40"))
    XCTAssertTrue(s.decidingPoint)
    XCTAssertEqual(computeScore(star, third + [.a]).currentSet, pt(1, 0))
  }

  func testStarPointWinFromAdvantage() {
    XCTAssertEqual(computeScore(star, deuce + sets("BB")).currentSet, pt(0, 1))
  }

  func testStarPointDeuceCountResetsEachGame() {
    let starGame = deuce + sets("ABBAA")
    let s = computeScore(star, starGame + deuce)
    XCTAssertEqual(s.currentSet, pt(1, 0))
    XCTAssertFalse(s.decidingPoint)
  }

  func testNotAppliedToTiebreaks() {
    let tb = toSixAll() + rep(.a, 6) + rep(.b, 6)
    let s = computeScore(golden, tb)
    XCTAssertEqual(s.currentGame, tiebreak(6, 6))
    XCTAssertFalse(s.decidingPoint)
    XCTAssertEqual(computeScore(golden, tb + [.a]).completedSets, [])
  }
}

final class FormatSetsTests: XCTestCase {
  let completed = [
    CompletedSet(games: pt(6, 4)),
    CompletedSet(games: pt(3, 6)),
    CompletedSet(games: pt(7, 6), tiebreak: pt(7, 5)),
  ]

  func testFromEachTeamsPointOfView() {
    XCTAssertEqual(formatSets(completed, from: .a), "6–4  3–6  7–6(5)")
    XCTAssertEqual(formatSets(completed, from: .b), "4–6  6–3  6–7(5)")
  }

  func testEmptyWhenNoSets() {
    XCTAssertEqual(formatSets([], from: .a), "")
  }
}

final class SavedMatchTests: XCTestCase {
  let match = SavedMatch(
    setup: MatchSetup(teamNames: PerTeam(a: "Us", b: "Them"), firstServer: .b, deuceRule: .star),
    points: [.a, .b, .a])

  func testRoundTrips() {
    XCTAssertEqual(SavedMatch.decode(match.encoded()), match)
  }

  func testMissingOrCorruptIsNil() {
    XCTAssertNil(SavedMatch.decode(nil))
    XCTAssertNil(SavedMatch.decode(Data()))
    XCTAssertNil(SavedMatch.decode(Data("{not json".utf8)))
  }

  func testOtherVersionIsNil() {
    var other = match
    other.version = 2
    XCTAssertNil(SavedMatch.decode(other.encoded()))
  }
}
