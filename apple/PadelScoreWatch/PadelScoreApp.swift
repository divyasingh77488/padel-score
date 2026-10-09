import SwiftUI

@main
struct PadelScoreApp: App {
  @StateObject private var model = MatchModel()

  var body: some Scene {
    WindowGroup {
      NavigationStack {
        if let setup = model.setup, let score = model.score {
          MatchView(model: model, setup: setup, score: score)
        } else {
          SetupView(model: model)
        }
      }
    }
  }
}
