import PadelScoreKit
import SwiftUI
import WatchKit

struct MatchView: View {
  @ObservedObject var model: MatchModel
  let setup: MatchSetup
  let score: MatchScore

  @State private var confirmNewMatch = false

  var body: some View {
    Group {
      if let winner = score.winner {
        MatchOverView(model: model, setup: setup, score: score, winner: winner)
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
            .disabled(model.points.isEmpty)
            .accessibilityLabel("Undo")
          }
          ToolbarItem(placement: .topBarTrailing) {
            Button {
              confirmNewMatch = true
            } label: {
              Image(systemName: "xmark")
            }
            .accessibilityLabel("New match")
          }
        }
      }
    }
    .alert("Start a new match?", isPresented: $confirmNewMatch) {
      Button("New match", role: .destructive) { model.newMatch() }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("The current match will be lost.")
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
          // Name and serve dot on the left, this team's games in the set on the right.
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
            Spacer(minLength: 4)
            Text("\(score.currentSet[team])")
              .font(.system(.title3, design: .rounded).weight(.heavy))
              .monospacedDigit()
              .foregroundStyle(.black)
              .padding(.horizontal, 8)
              .background(Capsule().fill(.white))
              .accessibilityLabel("\(score.currentSet[team]) games")
          }
          .padding(.horizontal, 10)
          Text(pointsText(team))
            .font(.system(size: 46, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .frame(maxHeight: .infinity)
        }
        .padding(.vertical, 4)
        .foregroundStyle(.white)
      }
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Point \(setup.teamNames[team])")
  }

  /// Which set is being played, sets won, and the tiebreak / deciding-point label.
  private var statusLine: String {
    var parts = ["SET \(score.completedSets.count + 1)"]
    if !score.completedSets.isEmpty {
      parts.append("Sets \(score.setsWon.a)–\(score.setsWon.b)")
    }
    if case .tiebreak = score.currentGame {
      parts.append("Tiebreak")
    } else if score.decidingPoint {
      parts.append(setup.deuceRule.label)
    }
    return parts.joined(separator: " · ")
  }

  private var scoreStrip: some View {
    Text(statusLine)
      .font(.footnote.weight(.bold))
      .monospacedDigit()
      .lineLimit(1)
      .minimumScaleFactor(0.7)
      .foregroundStyle(score.decidingPoint ? Theme.accent : .white)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 3)
      .background(.black)
  }
}

struct MatchOverView: View {
  @ObservedObject var model: MatchModel
  let setup: MatchSetup
  let score: MatchScore
  let winner: Team

  var body: some View {
    ScrollView {
      VStack(spacing: 8) {
        Text("Winner").font(.caption).foregroundStyle(.secondary)
        Text(setup.teamNames[winner])
          .font(.title3.weight(.bold))
          .foregroundStyle(Theme.color(winner))
        Text(formatSets(score.completedSets, from: winner))
          .font(.headline)
          .monospacedDigit()
        Button("New match") { model.newMatch() }
          .tint(Theme.accent)
        Button("Undo last point") { model.undo() }
      }
    }
  }
}
