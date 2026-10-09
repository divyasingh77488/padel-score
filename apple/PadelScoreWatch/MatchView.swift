import PadelScoreKit
import SwiftUI
import WatchKit

struct MatchView: View {
  @ObservedObject var model: MatchModel
  let record: MatchRecord
  let setup: MatchSetup
  let score: MatchScore

  @State private var confirmEnd = false

  init(model: MatchModel, record: MatchRecord) {
    self.model = model
    self.record = record
    self.setup = record.setup
    self.score = record.score
  }

  var body: some View {
    if model.isOver {
      MatchSummaryView(model: model, record: record, score: score)
    } else {
      VStack(spacing: 0) {
        half(.a)
        scoreStrip
        half(.b)
      }
      .ignoresSafeArea(edges: .bottom)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button {
            model.undo()
            WKInterfaceDevice.current().play(.directionDown)
          } label: {
            Image(systemName: "arrow.uturn.backward")
          }
          .disabled(record.points.isEmpty)
          .accessibilityLabel("Undo")
        }
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            confirmEnd = true
          } label: {
            Image(systemName: "xmark")
          }
          .accessibilityLabel("End match")
        }
      }
      .confirmationDialog("End this match?", isPresented: $confirmEnd) {
        Button("End match") { model.endMatch() }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text("You can sync the score so far to your phone.")
      }
    }
  }

  private func pointsText(_ team: Team) -> String {
    switch score.currentGame {
    case .regular(let display): return display[team]
    case .tiebreak(let points): return String(points[team])
    }
  }

  private func half(_ team: Team) -> some View {
    Button {
      model.addPoint(team)
      WKInterfaceDevice.current().play(.click)
    } label: {
      ZStack {
        Theme.color(team)
        VStack(spacing: 0) {
          HStack(spacing: 4) {
            Text(setup.teamNames[team])
              .font(.footnote.weight(.semibold))
              .lineLimit(1)
            if score.server == team {
              Circle()
                .fill(Theme.accent)
                .frame(width: 9, height: 9)
                .accessibilityLabel("Serving")
            }
          }
          Text(pointsText(team))
            .font(.system(size: 44, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .minimumScaleFactor(0.5)
            .lineLimit(1)
          if let label = gameLabel {
            Text(label)
              .font(.caption2.weight(.semibold))
              .opacity(0.85)
          }
        }
        .foregroundStyle(.white)
      }
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Point \(setup.teamNames[team])")
  }

  /// "Tiebreak", or the deciding-point rule name when the next point wins the game.
  private var gameLabel: String? {
    if case .tiebreak = score.currentGame { return "Tiebreak" }
    return score.decidingPoint ? setup.deuceRule.label : nil
  }

  /// Mini scoreboard like the phone's: a row per team, finished sets then the current set.
  private var scoreStrip: some View {
    VStack(spacing: 1) {
      boardRow(.a)
      boardRow(.b)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 3)
    .background(Color(white: 0.12))
  }

  private func boardRow(_ team: Team) -> some View {
    HStack(spacing: 8) {
      Text(setup.teamNames[team])
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)
      ForEach(Array(score.completedSets.enumerated()), id: \.offset) { _, set in
        Text("\(set.games[team])")
          .foregroundStyle(set.games[team] > set.games[team.other] ? Color.white : Color.secondary)
      }
      Text("\(score.currentSet[team])")
        .foregroundStyle(Theme.accent)
    }
    .font(.system(.footnote, design: .rounded).weight(.bold))
    .monospacedDigit()
  }
}

/// Shown when a match is won or ended early: the result, then sync it to the phone or not.
struct MatchSummaryView: View {
  @ObservedObject var model: MatchModel
  let record: MatchRecord
  let score: MatchScore

  @State private var confirmDiscard = false

  var body: some View {
    let ahead = leader(score)
    ScrollView {
      VStack(spacing: 8) {
        if let winner = score.winner {
          Text("Winner").font(.caption).foregroundStyle(.secondary)
          Text(record.setup.teamNames[winner])
            .font(.title3.weight(.bold))
            .foregroundStyle(Theme.color(winner))
        } else {
          Text("Match ended").font(.caption).foregroundStyle(.secondary)
          if let ahead {
            Text("\(record.setup.teamNames[ahead]) ahead")
              .font(.title3.weight(.bold))
              .foregroundStyle(Theme.color(ahead))
          } else {
            Text("Level").font(.title3.weight(.bold))
          }
        }
        let summary = formatScore(score, from: ahead ?? .a)
        if !summary.isEmpty {
          Text(summary)
            .font(.headline)
            .monospacedDigit()
        }

        Button {
          model.syncToPhone()
          WKInterfaceDevice.current().play(.success)
        } label: {
          Label("Sync to phone", systemImage: "iphone")
        }
        .tint(Theme.accent)
        .disabled(record.points.isEmpty)

        Button("Don't sync", role: .destructive) { confirmDiscard = true }

        if score.winner != nil {
          Button("Undo last point") { model.undo() }
        } else {
          Button("Resume") { model.resume() }
        }
      }
    }
    .confirmationDialog("Discard this match?", isPresented: $confirmDiscard) {
      Button("Discard", role: .destructive) { model.discard() }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("It won't be saved on your phone.")
    }
  }
}
