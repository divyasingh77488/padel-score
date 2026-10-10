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
///
/// The latest value is kept until Apple accepts it, and sent again whenever the connection
/// changes (watch paired, watch app installed, back in range) or the app comes to the front.
@MainActor
final class SyncSession: NSObject, ObservableObject {
  static let shared = SyncSession()

  /// How the link to the other device looks, for the phone to show when something is wrong.
  enum Status: Equatable {
    case connecting
    case noWatch
    case watchAppMissing
    case ready
    case failed(String)
  }

  private enum Key {
    static let next = "next"
    static let finished = "finished"
  }

  /// Watch: called with the next match set up on the phone, or nil.
  var onNextMatch: ((PlannedMatch?) -> Void)?
  /// Phone: called with the watch's recently finished matches.
  var onFinishedMatches: (([MatchRecord]) -> Void)?

  @Published private(set) var status: Status = .connecting

  /// The latest value to send, kept until Apple accepts it.
  private var pendingContext: [String: Any]?

  private var session: WCSession? { WCSession.isSupported() ? WCSession.default : nil }

  func activate() {
    guard let session else { return }
    session.delegate = self
    session.activate()
  }

  /// Phone: the match the watch should offer next (nil to clear it).
  func sendNextMatch(_ match: PlannedMatch?) {
    pendingContext = [Key.next: SyncCoding.encode(match)]
    flush()
  }

  /// Watch: the recently finished matches, newest first.
  func sendFinishedMatches(_ records: [MatchRecord]) {
    pendingContext = [Key.finished: SyncCoding.encode(records)]
    flush()
  }

  /// Reconnects and sends anything still waiting. Call when the app comes to the front.
  func refresh() {
    guard let session else { return }
    if session.activationState != .activated {
      activate()
      return
    }
    // Read anything the other device sent that didn't arrive through the delegate.
    let context = session.receivedApplicationContext
    if !context.isEmpty { handle(context: context) }
    flush()
  }

  private func flush() {
    guard let session, session.activationState == .activated else {
      status = .connecting
      return
    }
    #if os(iOS)
      guard session.isPaired else {
        status = .noWatch
        return
      }
      guard session.isWatchAppInstalled else {
        status = .watchAppMissing
        return
      }
    #endif
    guard let context = pendingContext else {
      status = .ready
      return
    }
    do {
      try session.updateApplicationContext(context)
      pendingContext = nil
      status = .ready
    } catch {
      // Kept in pendingContext and tried again when the connection changes.
      status = .failed(error.localizedDescription)
    }
  }

  fileprivate func didActivate() {
    flush()
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

  nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
    Task { @MainActor in self.flush() }
  }

  #if os(iOS)
    /// The watch was paired or unpaired, or the watch app installed or removed.
    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
      Task { @MainActor in self.flush() }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
      // Happens when switching to another paired watch; reconnect to the new one.
      WCSession.default.activate()
    }
  #endif
}
