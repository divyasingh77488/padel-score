import Foundation
import PadelScoreKit

/// Holds the match in progress and saves it after every change, so closing the app or
/// restarting the watch never loses it. Finished matches are sent to the phone when they end.
@MainActor
final class MatchModel: ObservableObject {
  private static let matchKey = "padel-battle/watch-match"
  private static let legacyMatchKey = "padel-score/match"
  private static let lastSetupKey = "padel-score/last-setup"
  private static let startedNextKey = "padel-battle/started-next"
  private static let outboxKey = "padel-battle/finished-outbox"
  /// How many recent finished matches are kept for the phone to pick up.
  private static let outboxSize = 20

  @Published private(set) var current: MatchRecord?
  /// The match set up on the phone, ready to start (nil once started here).
  @Published private(set) var next: PlannedMatch?

  /// The setup of the most recent match, to prefill the setup screen.
  private(set) var lastSetup: MatchSetup

  /// The latest match received from the phone, shown as `next` unless it was started here.
  private var fromPhone: PlannedMatch?
  /// The id of the phone's match already started here, hidden until the phone sends a new one.
  private var startedNextId: UUID?
  /// Recently finished matches, newest first, waiting for (or already seen by) the phone.
  private var outbox: [MatchRecord]

  private let defaults: UserDefaults
  private let sync = SyncSession.shared

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    if let record = SyncCoding.decode(MatchRecord.self, from: defaults.data(forKey: Self.matchKey))
    {
      current = record
    } else if let legacy = SavedMatch.decode(defaults.data(forKey: Self.legacyMatchKey)) {
      // A match saved by the first watch version.
      current = MatchRecord(setup: legacy.setup, points: legacy.points)
    }
    lastSetup =
      defaults.data(forKey: Self.lastSetupKey).flatMap {
        try? JSONDecoder().decode(MatchSetup.self, from: $0)
      }
      ?? MatchSetup(teamNames: PerTeam(a: "Us", b: "Them"), firstServer: .a, deuceRule: .golden)
    startedNextId = SyncCoding.decode(UUID.self, from: defaults.data(forKey: Self.startedNextKey))
    outbox =
      SyncCoding.decode([MatchRecord].self, from: defaults.data(forKey: Self.outboxKey)) ?? []

    sync.onNextMatch = { [weak self] match in self?.receiveNext(match) }
    sync.activate()
    if !outbox.isEmpty { sync.sendFinishedMatches(outbox) }
  }

  var setup: MatchSetup? { current?.setup }
  var points: [Team] { current?.points ?? [] }
  var score: MatchScore? { current?.score }

  func startMatch(_ newSetup: MatchSetup, id: UUID = UUID()) {
    current = MatchRecord(id: id, setup: newSetup)
    lastSetup = newSetup
    defaults.set(try? JSONEncoder().encode(newSetup), forKey: Self.lastSetupKey)
    saveCurrent()
  }

  /// Starts the match set up on the phone. It keeps the same id, so the phone can clear it.
  func startNext() {
    guard let match = next else { return }
    setStartedNextId(match.id)
    next = nil
    startMatch(match.setup, id: match.id)
  }

  func addPoint(_ team: Team) {
    guard var record = current, record.finishedAt == nil, record.score.winner == nil else {
      return
    }
    record.points.append(team)
    current = record
    saveCurrent()
  }

  func undo() {
    guard var record = current, !record.points.isEmpty else { return }
    record.points.removeLast()
    record.finishedAt = nil
    current = record
    saveCurrent()
  }

  /// True when the match is over: won, or ended early from the ✕ button.
  var isOver: Bool {
    guard let current else { return false }
    return current.finishedAt != nil || current.score.winner != nil
  }

  /// Ends the match before it's won (court time over). It can still be resumed or synced.
  func endMatch() {
    guard var record = current, record.finishedAt == nil else { return }
    record.finishedAt = Date()
    current = record
    saveCurrent()
  }

  /// Goes back to a match ended early by mistake.
  func resume() {
    guard var record = current else { return }
    record.finishedAt = nil
    current = record
    saveCurrent()
  }

  /// Sends the match to the phone's history and clears it from the watch.
  func syncToPhone() {
    if var record = current, !record.points.isEmpty {
      if record.finishedAt == nil { record.finishedAt = Date() }
      outbox = Array(([record] + outbox.filter { $0.id != record.id }).prefix(Self.outboxSize))
      defaults.set(SyncCoding.encode(outbox), forKey: Self.outboxKey)
      sync.sendFinishedMatches(outbox)
    }
    current = nil
    saveCurrent()
  }

  /// Clears the match without sending it to the phone.
  func discard() {
    // A discarded match from the phone is offered again, as the phone still lists it.
    if let id = current?.id, id == startedNextId {
      setStartedNextId(nil)
      next = fromPhone
    }
    current = nil
    saveCurrent()
  }

  /// Reconnects to the phone, e.g. when the app comes to the front.
  func refreshSync() {
    sync.refresh()
  }

  private func saveCurrent() {
    if let current {
      defaults.set(SyncCoding.encode(current), forKey: Self.matchKey)
    } else {
      defaults.removeObject(forKey: Self.matchKey)
    }
    defaults.removeObject(forKey: Self.legacyMatchKey)
  }

  private func setStartedNextId(_ id: UUID?) {
    startedNextId = id
    if let id {
      defaults.set(SyncCoding.encode(id), forKey: Self.startedNextKey)
    } else {
      defaults.removeObject(forKey: Self.startedNextKey)
    }
  }

  private func receiveNext(_ match: PlannedMatch?) {
    fromPhone = match
    next = match?.id == startedNextId ? nil : match
  }
}
