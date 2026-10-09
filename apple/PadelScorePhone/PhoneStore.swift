import Foundation
import PadelScoreKit

/// Everything the phone app keeps: the next match for the watch, a match played on the phone,
/// and the history. Saved after every change.
@MainActor
final class PhoneStore: ObservableObject {
  private enum Key {
    static let next = "padel-battle/next"
    static let current = "padel-battle/phone-match"
    static let history = "padel-battle/history"
    static let seenFromWatch = "padel-battle/seen-from-watch"
    static let lastSetup = "padel-battle/last-setup"
  }

  /// The match set up for the watch. Sending another one replaces it.
  @Published private(set) var next: PlannedMatch?
  /// A match being scored on the phone itself.
  @Published private(set) var current: MatchRecord?
  /// Finished matches, newest first.
  @Published private(set) var history: [MatchRecord] = []

  private(set) var lastSetup: MatchSetup

  /// Ids of finished watch matches already taken into the history, so a match deleted from the
  /// history isn't added back when the watch re-sends its recent matches.
  private var seenFromWatch: Set<UUID>

  private let defaults: UserDefaults
  private let sync = SyncSession.shared

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    next = SyncCoding.decode(PlannedMatch.self, from: defaults.data(forKey: Key.next))
    current = SyncCoding.decode(MatchRecord.self, from: defaults.data(forKey: Key.current))
    history = SyncCoding.decode([MatchRecord].self, from: defaults.data(forKey: Key.history)) ?? []
    seenFromWatch = Set(
      SyncCoding.decode([UUID].self, from: defaults.data(forKey: Key.seenFromWatch)) ?? [])
    lastSetup =
      SyncCoding.decode(MatchSetup.self, from: defaults.data(forKey: Key.lastSetup))
      ?? MatchSetup(teamNames: PerTeam(a: "Team A", b: "Team B"), firstServer: .a, deuceRule: .golden)

    sync.onFinishedMatches = { [weak self] records in self?.receiveFinished(records) }
    sync.activate()
    sync.sendNextMatch(next)
  }

  // MARK: The next match for the watch

  /// Sets the match the watch offers next, replacing any previous one.
  func sendToWatch(_ setup: MatchSetup) {
    remember(setup)
    next = PlannedMatch(setup: setup)
    saveNext()
  }

  func clearNext() {
    next = nil
    saveNext()
  }

  // MARK: Playing on the phone

  func playOnPhone(_ setup: MatchSetup) {
    remember(setup)
    current = MatchRecord(setup: setup)
    saveCurrent()
  }

  /// Plays the match meant for the watch on the phone instead.
  func playNextOnPhone() {
    guard let match = next else { return }
    clearNext()
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

  private func receiveFinished(_ records: [MatchRecord]) {
    // Oldest first, so the newest ends up at the top of the history.
    for record in records.reversed() where !seenFromWatch.contains(record.id) {
      seenFromWatch.insert(record.id)
      history = MatchHistory.adding(record, to: history)
      // The match sent to the watch has been played.
      if next?.id == record.id { clearNext() }
    }
    defaults.set(SyncCoding.encode(Array(seenFromWatch)), forKey: Key.seenFromWatch)
    saveHistory()
  }

  // MARK: Saving

  private func remember(_ setup: MatchSetup) {
    lastSetup = setup
    defaults.set(SyncCoding.encode(setup), forKey: Key.lastSetup)
  }

  private func saveNext() {
    if let next {
      defaults.set(SyncCoding.encode(next), forKey: Key.next)
    } else {
      defaults.removeObject(forKey: Key.next)
    }
    sync.sendNextMatch(next)
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
