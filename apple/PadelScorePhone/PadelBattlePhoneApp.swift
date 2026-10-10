import SwiftUI

@main
struct PadelBattlePhoneApp: App {
  @StateObject private var store = PhoneStore()
  @Environment(\.scenePhase) private var scenePhase

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
