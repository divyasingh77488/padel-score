import PadelScoreKit
import SwiftUI
import UIKit

/// Scoring a match on the phone: two big tap halves and the scoreboard in the middle.
struct PhoneMatchView: View {
  @ObservedObject var store: PhoneStore
  @State private var confirmLeave = false

  var body: some View {
    if let record = store.current {
      let score = record.score
      ZStack {
        VStack(spacing: 0) {
          half(.a, record: record, score: score)
          middleBar(record: record, score: score)
          half(.b, record: record, score: score)
        }
        if let winner = score.winner {
          MatchOverCard(
            record: record, score: score, winner: winner,
            onSave: { store.leaveMatch(save: true) },
            onDiscard: { store.leaveMatch(save: false) },
            onUndo: { store.undo() })
        }
      }
      .background(Color.black)
      .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
      .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
      .confirmationDialog("End this match?", isPresented: $confirmLeave, titleVisibility: .visible) {
        Button("Save to history") { store.leaveMatch(save: true) }
          .disabled(record.points.isEmpty)
        Button("Discard", role: .destructive) { store.leaveMatch(save: false) }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text("Save the score so far to your history, or discard it.")
      }
    }
  }

  private func pointsText(_ score: MatchScore, _ team: Team) -> String {
    switch score.currentGame {
    case .regular(let display): return display[team]
    case .tiebreak(let points): return String(points[team])
    }
  }

  private func half(_ team: Team, record: MatchRecord, score: MatchScore) -> some View {
    Button {
      store.addPoint(team)
      UIImpactFeedbackGenerator(style: .light).impactOccurred()
    } label: {
      ZStack {
        Theme.color(team)
        VStack(spacing: 4) {
          HStack(spacing: 10) {
            Text(record.setup.teamNames[team])
              .font(.title2.weight(.bold))
              .lineLimit(1)
            if score.server == team && score.winner == nil {
              Circle()
                .fill(Theme.accent)
                .overlay(Circle().stroke(.white, lineWidth: 2))
                .frame(width: 18, height: 18)
                .accessibilityLabel("Serving")
            }
          }
          Text(pointsText(score, team))
            .font(.system(size: 120, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .minimumScaleFactor(0.5)
            .lineLimit(1)
          if case .tiebreak = score.currentGame {
            Text("Tiebreak").font(.headline).opacity(0.85)
          } else if score.decidingPoint {
            Text("\(record.setup.deuceRule.label): next point wins")
              .font(.headline)
              .opacity(0.85)
          }
        }
        .foregroundStyle(.white)
        .padding()
      }
    }
    .buttonStyle(.plain)
    .disabled(score.winner != nil)
    .accessibilityLabel("Point \(record.setup.teamNames[team])")
  }

  private func middleBar(record: MatchRecord, score: MatchScore) -> some View {
    HStack(spacing: 12) {
      VStack(spacing: 4) {
        boardRow(.a, record: record, score: score)
        boardRow(.b, record: record, score: score)
      }
      Button("Undo") { store.undo() }
        .buttonStyle(.bordered)
        .disabled(record.points.isEmpty)
      Button("End") { confirmLeave = true }
        .buttonStyle(.bordered)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(Color(white: 0.12))
  }

  private func boardRow(_ team: Team, record: MatchRecord, score: MatchScore) -> some View {
    HStack(spacing: 10) {
      Text(record.setup.teamNames[team])
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)
      ForEach(Array(score.completedSets.enumerated()), id: \.offset) { _, set in
        Text("\(set.games[team])")
          .foregroundStyle(set.games[team] > set.games[team.other] ? Color.white : Color.secondary)
      }
      if score.winner == nil {
        Text("\(score.currentSet[team])").foregroundStyle(Theme.accent)
      }
    }
    .font(.system(.title3, design: .rounded).weight(.bold))
    .monospacedDigit()
  }
}

private struct MatchOverCard: View {
  let record: MatchRecord
  let score: MatchScore
  let winner: Team
  let onSave: () -> Void
  let onDiscard: () -> Void
  let onUndo: () -> Void

  var body: some View {
    ZStack {
      Color.black.opacity(0.85).ignoresSafeArea()
      VStack(spacing: 14) {
        Text("WINNER").font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
        Text(record.setup.teamNames[winner])
          .font(.largeTitle.weight(.heavy))
          .foregroundStyle(Theme.color(winner))
        Text(formatSets(score.completedSets, from: winner))
          .font(.title.weight(.bold))
          .monospacedDigit()
        Button {
          onSave()
        } label: {
          Text("Save to history").font(.headline).frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(Theme.accent)
        .foregroundStyle(.black)
        HStack {
          Button("Undo last point", action: onUndo)
          Spacer()
          Button("Discard", role: .destructive, action: onDiscard)
        }
      }
      .padding(24)
      .background(RoundedRectangle(cornerRadius: 20).fill(Color(white: 0.12)))
      .padding(24)
    }
  }
}
