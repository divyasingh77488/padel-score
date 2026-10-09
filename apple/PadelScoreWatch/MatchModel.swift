import Foundation
import PadelScoreKit

/// Holds the match in progress and saves it after every change, so closing the app or
/// restarting the watch never loses it.
@MainActor
final class MatchModel: ObservableObject {
  private static let matchKey = "padel-score/match"
  private static let lastSetupKey = "padel-score/last-setup"

  @Published private(set) var setup: MatchSetup?
  @Published private(set) var points: [Team] = []

  /// The setup of the most recent match, to prefill the setup screen.
  private(set) var lastSetup: MatchSetup

  private let defaults: UserDefaults

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    let saved = SavedMatch.decode(defaults.data(forKey: Self.matchKey))
    setup = saved?.setup
    points = saved?.points ?? []
    lastSetup =
      defaults.data(forKey: Self.lastSetupKey).flatMap {
        try? JSONDecoder().decode(MatchSetup.self, from: $0)
      }
      ?? MatchSetup(teamNames: PerTeam(a: "Us", b: "Them"), firstServer: .a, deuceRule: .golden)
  }

  var score: MatchScore? {
    setup.map { computeScore($0, points) }
  }

  func startMatch(_ newSetup: MatchSetup) {
    setup = newSetup
    points = []
    lastSetup = newSetup
    defaults.set(try? JSONEncoder().encode(newSetup), forKey: Self.lastSetupKey)
    save()
  }

  func addPoint(_ team: Team) {
    guard score?.winner == nil else { return }
    points.append(team)
    save()
  }

  func undo() {
    guard !points.isEmpty else { return }
    points.removeLast()
    save()
  }

  func newMatch() {
    setup = nil
    points = []
    save()
  }

  private func save() {
    if let setup {
      defaults.set(SavedMatch(setup: setup, points: points).encoded(), forKey: Self.matchKey)
    } else {
      defaults.removeObject(forKey: Self.matchKey)
    }
  }
}
