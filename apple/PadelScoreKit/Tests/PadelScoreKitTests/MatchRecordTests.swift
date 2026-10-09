import XCTest

@testable import PadelScoreKit

final class MatchRecordTests: XCTestCase {
  let setup = MatchSetup(
    teamNames: PerTeam(a: "Us", b: "Them"), firstServer: .a, deuceRule: .golden)
  /// Points for a 6–0 6–0 win by A.
  let finishedPoints = Array(repeating: Team.a, count: 48)

  func testHistoryAddsFinishedMatchFirstWithFinishDate() {
    let older = MatchRecord(setup: setup, points: finishedPoints, finishedAt: Date())
    let match = MatchRecord(setup: setup, points: finishedPoints)
    let history = MatchHistory.adding(match, to: [older])
    XCTAssertEqual(history.map(\.id), [match.id, older.id])
    XCTAssertNotNil(history[0].finishedAt)
  }

  func testHistoryIgnoresUnfinishedMatch() {
    let match = MatchRecord(setup: setup, points: [.a, .b])
    XCTAssertEqual(MatchHistory.adding(match, to: []), [])
  }

  func testHistoryReplacesSameMatchInsteadOfDuplicating() {
    let match = MatchRecord(setup: setup, points: finishedPoints, finishedAt: Date())
    let history = MatchHistory.adding(match, to: MatchHistory.adding(match, to: []))
    XCTAssertEqual(history.count, 1)
  }

  func testHistoryIsCapped() {
    let full = (0..<MatchHistory.maxEntries).map { _ in
      MatchRecord(setup: setup, points: finishedPoints, finishedAt: Date())
    }
    let match = MatchRecord(setup: setup, points: finishedPoints)
    let history = MatchHistory.adding(match, to: full)
    XCTAssertEqual(history.count, MatchHistory.maxEntries)
    XCTAssertEqual(history[0].id, match.id)
  }

  func testCodingRoundTrips() {
    let planned = [PlannedMatch(setup: setup)]
    XCTAssertEqual(
      SyncCoding.decode([PlannedMatch].self, from: SyncCoding.encode(planned))?.map(\.id),
      planned.map(\.id))
    let record = MatchRecord(setup: setup, points: [.a, .b, .a])
    XCTAssertEqual(
      SyncCoding.decode(MatchRecord.self, from: SyncCoding.encode(record))?.points, record.points)
  }

  func testDecodingBadDataIsNil() {
    XCTAssertNil(SyncCoding.decode(MatchRecord.self, from: nil))
    XCTAssertNil(SyncCoding.decode(MatchRecord.self, from: Data("nope".utf8)))
  }
}
