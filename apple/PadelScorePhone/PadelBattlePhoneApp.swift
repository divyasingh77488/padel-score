import SwiftUI

@main
struct PadelBattlePhoneApp: App {
  @StateObject private var store = PhoneStore()
  @Environment(\.scenePhase) private var scenePhase

  init() {
    // Answers the watch even when iOS launches the app in the background just for that.
    SyncSession.shared.activate()
  }

  var body: some Scene {
    WindowGroup {
      Group {
        if store.current != nil {
          PhoneMatchView(store: store)
        } else {
          HomeView(store: store)
        }
      }
      .preferredColorScheme(.dark)
      .onChange(of: scenePhase) { _, phase in
        if phase == .active { store.resendToWatch() }
      }
    }
  }
}
