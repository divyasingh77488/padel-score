import SwiftUI

@main
struct PadelScoreApp: App {
  @StateObject private var model = MatchModel()
  @Environment(\.scenePhase) private var scenePhase

  var body: some Scene {
    WindowGroup {
      NavigationStack {
        if let record = model.current {
          MatchView(model: model, record: record)
        } else {
          SetupView(model: model)
        }
      }
      .onChange(of: scenePhase) { _, phase in
        if phase == .active { model.refreshSync() }
      }
    }
  }
}
