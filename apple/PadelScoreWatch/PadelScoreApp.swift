import SwiftUI

@main
struct PadelScoreApp: App {
  @StateObject private var model = MatchModel()

  var body: some Scene {
    WindowGroup {
      NavigationStack {
        if let record = model.current {
          MatchView(model: model, record: record)
        } else {
          SetupView(model: model)
        }
      }
    }
  }
}
