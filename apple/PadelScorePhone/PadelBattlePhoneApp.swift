import SwiftUI

@main
struct PadelBattlePhoneApp: App {
  @StateObject private var store = PhoneStore()

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
    }
  }
}
