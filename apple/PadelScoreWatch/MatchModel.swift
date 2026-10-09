import Foundation
import PadelScoreKit

/// Holds the match in progress and saves it after every change, so closing the app or
/// restarting the watch never loses it. Keeps the phone informed through `SyncSession`.
@MainActor
final class MatchModel: ObservableObject {
  private static let matchKey = "padel-battle/watch-match"
  private static let legacyMatchKey = "padel-score/match"
  private static let lastSetupKey = "padel-score/last-setup"
  private static let startedKey = "padel-battle/started-planned"

  @Published private(set) var current: MatchRecord?
  /// Matches set up on the phone that haven't been started yet.
  @Published private(set) var planned: [PlannedMatch] = []

  /// The setup of the most recent match, to prefill the setup screen.
  private(set) var lastSetup: MatchSetup

  /// Planned matches already started here, hidden until the phone's list catches up.
  private var startedPlannedIds: Set<UUID>
  private var latestFromPhone: [PlannedMatch] = []

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
    startedPlannedIds = Set(
      SyncCoding.decode([UUID].self, from: defaults.data(forKey: Self.startedKey)) ?? [])

    sync.onPlannedMatches = { [weak self] planned in self?.receivePlanned(planned) }
    sync.activate()
    sync.sendLiveMatch(current)
  }

  var setup: MatchSetup? { current?.setup }
  var points: [Team] { current?.points ?? [] }
  var score: MatchScore? { current?.score }

  func startMatch(_ newSetup: MatchSetup, id: UUID = UUID()) {
    current = MatchRecord(id: id, setup: newSetup)
    lastSetup = newSetup
    defaults.set(try? JSONEncoder().encode(newSetup), forKey: Self.lastSetupKey)
    changed()
  }

  /// Starts a match that was set up on the phone. It keeps the same id, so the phone can match
  /// the live score to it and take it off its list.
  func startPlanned(_ match: PlannedMatch) {
    startedPlannedIds.insert(match.id)
    defaults.set(SyncCoding.encode(Array(startedPlannedIds)), forKey: Self.startedKey)
    refreshPlanned()
    startMatch(match.setup, id: match.id)
  }

  func addPoint(_ team: Team) {
    guard var record = current, record.score.winner == nil else { return }
    record.points.append(team)
    current = record
    changed()
  }

  func undo() {
    guard var record = current, !record.points.isEmpty else { return }
    record.points.removeLast()
    current = record
    changed()
  }

  /// Leaves the current match. A finished match is sent to the phone's history.
  func newMatch() {
    if var record = current, record.score.winner != nil {
      record.finishedAt = Date()
      sync.sendFinishedMatch(record)
    }
    current = nil
    changed()
  }

  private func changed() {
    if let current {
      defaults.set(SyncCoding.encode(current), forKey: Self.matchKey)
    } else {
      defaults.removeObject(forKey: Self.matchKey)
    }
    defaults.removeObject(forKey: Self.legacyMatchKey)
    sync.sendLiveMatch(current)
  }

  private func receivePlanned(_ fromPhone: [PlannedMatch]) {
    latestFromPhone = fromPhone
    // Forget started ids the phone has already removed from its list.
    let phoneIds = Set(fromPhone.map(\.id))
    startedPlannedIds.formIntersection(phoneIds)
    defaults.set(SyncCoding.encode(Array(startedPlannedIds)), forKey: Self.startedKey)
    refreshPlanned()
  }

  private func refreshPlanned() {
    planned = latestFromPhone.filter { !startedPlannedIds.contains($0.id) }
  }
}
