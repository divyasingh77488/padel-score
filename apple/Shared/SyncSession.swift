import Foundation
import PadelScoreKit
import WatchConnectivity

/// The link between the phone and the watch (WatchConnectivity). Compiled into both apps.
///
/// - Phone → watch, application context: the matches set up on the phone, ready to start.
/// - Watch → phone, application context: the match being played on the watch (or none).
/// - Watch → phone, user info: each finished match, queued until delivered, for the history.
///
/// Application context only keeps the latest value and is delivered whenever the other device is
/// reachable, so a phone left in a bag simply catches up later.
@MainActor
final class SyncSession: NSObject {
  static let shared = SyncSession()

  private enum Key {
    static let planned = "planned"
    static let live = "live"
    static let finished = "finished"
  }

  /// Watch: called with the matches set up on the phone.
  var onPlannedMatches: (([PlannedMatch]) -> Void)?
  /// Phone: called with the match being played on the watch, or nil when there is none.
  var onLiveMatch: ((MatchRecord?) -> Void)?
  /// Phone: called with each match finished on the watch.
  var onFinishedMatch: ((MatchRecord) -> Void)?

  private var pendingContext: [String: Any]?

  private var session: WCSession? { WCSession.isSupported() ? WCSession.default : nil }

  func activate() {
    guard let session else { return }
    session.delegate = self
    session.activate()
  }

  /// Phone: tell the watch which matches are ready to start.
  func sendPlannedMatches(_ planned: [PlannedMatch]) {
    updateContext([Key.planned: SyncCoding.encode(planned)])
  }

  /// Watch: tell the phone about the match in progress (nil when none).
  func sendLiveMatch(_ record: MatchRecord?) {
    updateContext([Key.live: SyncCoding.encode(record)])
  }

  /// Watch: hand a finished match to the phone's history. Queued until the phone receives it.
  func sendFinishedMatch(_ record: MatchRecord) {
    guard let session, session.activationState == .activated else { return }
    session.transferUserInfo([Key.finished: SyncCoding.encode(record)])
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
    if let data = context[Key.planned] as? Data,
      let planned = SyncCoding.decode([PlannedMatch].self, from: data)
    {
      onPlannedMatches?(planned)
    }
    if let data = context[Key.live] as? Data {
      onLiveMatch?(SyncCoding.decode(MatchRecord.self, from: data))
    }
  }

  fileprivate func handle(userInfo: [String: Any]) {
    if let data = userInfo[Key.finished] as? Data,
      let record = SyncCoding.decode(MatchRecord.self, from: data)
    {
      onFinishedMatch?(record)
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

  nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
    let info = userInfo
    Task { @MainActor in self.handle(userInfo: info) }
  }

  #if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
      // Happens when switching to another paired watch; reconnect to the new one.
      WCSession.default.activate()
    }
  #endif
}
