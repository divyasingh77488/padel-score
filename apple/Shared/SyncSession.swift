import Foundation
import PadelScoreKit
import WatchConnectivity

/// The link between the phone and the watch (WatchConnectivity). Compiled into both apps.
///
/// Only two things travel, both as application context (Apple keeps the latest value and delivers
/// it whenever the other device is in range, including in the simulator):
/// - Phone → watch: the next match to play, set up on the phone (or none).
/// - Watch → phone: the most recently finished matches. The phone ignores ones it has already
///   seen, so re-delivery is harmless and deleted history entries don't come back.
///
/// Nothing is sent while a match is being played; the result syncs when it ends.
@MainActor
final class SyncSession: NSObject {
  static let shared = SyncSession()

  private enum Key {
    static let next = "next"
    static let finished = "finished"
  }

  /// Watch: called with the next match set up on the phone, or nil.
  var onNextMatch: ((PlannedMatch?) -> Void)?
  /// Phone: called with the watch's recently finished matches.
  var onFinishedMatches: (([MatchRecord]) -> Void)?

  private var pendingContext: [String: Any]?

  private var session: WCSession? { WCSession.isSupported() ? WCSession.default : nil }

  func activate() {
    guard let session else { return }
    session.delegate = self
    session.activate()
  }

  /// Phone: the match the watch should offer next (nil to clear it).
  func sendNextMatch(_ match: PlannedMatch?) {
    updateContext([Key.next: SyncCoding.encode(match)])
  }

  /// Watch: the recently finished matches, newest first.
  func sendFinishedMatches(_ records: [MatchRecord]) {
    updateContext([Key.finished: SyncCoding.encode(records)])
  }

  private func updateContext(_ context: [String: Any]) {
    guard let session, session.activationState == .activated else {
      pendingContext = context
      return
    }
    #if os(iOS)
      guard session.isPaired, session.isWatchAppInstalled else { return }
    #endif
    try? session.updateApplicationContext(context)
  }

  fileprivate func didActivate() {
    if let pending = pendingContext {
      pendingContext = nil
      updateContext(pending)
    }
    // Pick up whatever the other device sent while this app wasn't running.
    if let context = session?.receivedApplicationContext, !context.isEmpty {
      handle(context: context)
    }
  }

  fileprivate func handle(context: [String: Any]) {
    if let data = context[Key.next] as? Data {
      onNextMatch?(SyncCoding.decode(PlannedMatch.self, from: data))
    }
    if let data = context[Key.finished] as? Data,
      let records = SyncCoding.decode([MatchRecord].self, from: data)
    {
      onFinishedMatches?(records)
    }
  }
}

extension SyncSession: WCSessionDelegate {
  nonisolated func session(
    _ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    Task { @MainActor in self.didActivate() }
  }

  nonisolated func session(
    _ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]
  ) {
    let context = applicationContext
    Task { @MainActor in self.handle(context: context) }
  }

  #if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
      // Happens when switching to another paired watch; reconnect to the new one.
      WCSession.default.activate()
    }
  #endif
}
