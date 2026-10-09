import Foundation
import PadelScoreKit

/// Everything the phone app keeps: matches ready for the watch, a match played on the phone, the
/// live match from the watch, and the history. Saved after every change.
@MainActor
final class PhoneStore: ObservableObject {
  private enum Key {
    static let planned = "padel-battle/planned"
    static let current = "padel-battle/phone-match"
    static let history = "padel-battle/history"
    static let lastSetup = "padel-battle/last-setup"
  }

  /// Matches set up here and sent to the watch, oldest first.
  @Published private(set) var planned: [PlannedMatch] = []
  /// A match being scored on the phone itself.
  @Published private(set) var current: MatchRecord?
  /// The match being played on the watch, as last reported by it.
  @Published private(set) var watchLive: MatchRecord?
  /// Finished matches, newest first.
  @Published private(set) var history: [MatchRecord] = []

  private(set) var lastSetup: MatchSetup

  private let defaults: UserDefaults
  private let sync = SyncSession.shared

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    planned = SyncCoding.decode([PlannedMatch].self, from: defaults.data(forKey: Key.planned)) ?? []
    current = SyncCoding.decode(MatchRecord.self, from: defaults.data(forKey: Key.current))
    history = SyncCoding.decode([MatchRecord].self, from: defaults.data(forKey: Key.history)) ?? []
    lastSetup =
      SyncCoding.decode(MatchSetup.self, from: defaults.data(forKey: Key.lastSetup))
      ?? MatchSetup(teamNames: PerTeam(a: "Team A", b: "Team B"), firstServer: .a, deuceRule: .golden)

    sync.onLiveMatch = { [weak self] record in self?.receiveLive(record) }
    sync.onFinishedMatch = { [weak self] record in self?.receiveFinished(record) }
    sync.activate()
    sync.sendPlannedMatches(planned)
  }

  // MARK: Matches for the watch

  func sendToWatch(_ setup: MatchSetup) {
    remember(setup)
    planned.append(PlannedMatch(setup: setup))
    savePlanned()
  }

  func removePlanned(_ id: UUID) {
    planned.removeAll { $0.id == id }
    savePlanned()
  }

  // MARK: Playing on the phone

  func playOnPhone(_ setup: MatchSetup) {
    remember(setup)
    current = MatchRecord(setup: setup)
    saveCurrent()
  }

  func playOnPhone(_ match: PlannedMatch) {
    removePlanned(match.id)
    current = MatchRecord(id: match.id, setup: match.setup)
    saveCurrent()
  }

  func addPoint(_ team: Team) {
    guard var record = current, record.score.winner == nil else { return }
    record.points.append(team)
    current = record
    saveCurrent()
  }

  func undo() {
    guard var record = current, !record.points.isEmpty else { return }
    record.points.removeLast()
    current = record
    saveCurrent()
  }

  /// Leaves the phone match; a finished one goes into the history.
  func leaveMatch() {
    if let record = current {
      history = MatchHistory.adding(record, to: history)
      saveHistory()
    }
    current = nil
    saveCurrent()
  }

  // MARK: History

  func deleteHistory(_ id: UUID) {
    history.removeAll { $0.id == id }
    saveHistory()
  }

  func clearHistory() {
    history = []
    saveHistory()
  }

  // MARK: From the watch

  private func receiveLive(_ record: MatchRecord?) {
    watchLive = record
    // A match started on the watch from this phone's list is no longer waiting.
    if let id = record?.id, planned.contains(where: { $0.id == id }) {
      removePlanned(id)
    }
  }

  private func receiveFinished(_ record: MatchRecord) {
    history = MatchHistory.adding(record, to: history)
    saveHistory()
  }

  // MARK: Saving

  private func remember(_ setup: MatchSetup) {
    lastSetup = setup
    defaults.set(SyncCoding.encode(setup), forKey: Key.lastSetup)
  }

  private func savePlanned() {
    defaults.set(SyncCoding.encode(planned), forKey: Key.planned)
    sync.sendPlannedMatches(planned)
  }

  private func saveCurrent() {
    if let current {
      defaults.set(SyncCoding.encode(current), forKey: Key.current)
    } else {
      defaults.removeObject(forKey: Key.current)
    }
  }

  private func saveHistory() {
    defaults.set(SyncCoding.encode(history), forKey: Key.history)
  }
}
