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
