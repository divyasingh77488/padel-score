import PadelScoreKit
import SwiftUI

struct HomeView: View {
  @ObservedObject var store: PhoneStore
  @State private var showNewMatch = false

  var body: some View {
    NavigationStack {
      List {
        if let live = store.watchLive {
          Section("On your watch") {
            LiveMatchCard(record: live)
          }
        }

        Section {
          if store.planned.isEmpty {
            Text("Set up a match here and it appears on your watch, ready to start.")
              .foregroundStyle(.secondary)
          }
          ForEach(store.planned) { match in
            PlannedRow(match: match) { store.playOnPhone(match) }
          }
          .onDelete { offsets in
            let ids = offsets.map { store.planned[$0].id }
            ids.forEach(store.removePlanned)
          }
          Button {
            showNewMatch = true
          } label: {
            Label("New match", systemImage: "plus.circle.fill")
              .font(.headline)
          }
        } header: {
          Text("Ready on your watch")
        } footer: {
          if !store.planned.isEmpty {
            Text("Open Padel Battle on your watch and tap a match to start it. Swipe to remove.")
          }
        }

        Section {
          NavigationLink {
            HistoryView(store: store)
          } label: {
            Label("History", systemImage: "clock.arrow.circlepath")
              .badge(store.history.count)
          }
        }
      }
      .navigationTitle("Padel Battle")
      .sheet(isPresented: $showNewMatch) {
        NewMatchView(store: store)
      }
    }
  }
}

private struct PlannedRow: View {
  let match: PlannedMatch
  let playOnPhone: () -> Void

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 2) {
        TeamsText(names: match.setup.teamNames)
          .font(.headline)
        Text(match.setup.deuceRule.label)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
      Button("Play on phone", action: playOnPhone)
        .buttonStyle(.bordered)
        .font(.caption)
    }
  }
}

/// "Team A vs Team B" in the team colours.
struct TeamsText: View {
  let names: PerTeam<String>

  var body: some View {
    Text(names.a).foregroundStyle(Theme.color(.a))
      + Text(" vs ").foregroundStyle(.secondary)
      + Text(names.b).foregroundStyle(Theme.color(.b))
  }
}

/// The live score of the match on the watch.
private struct LiveMatchCard: View {
  let record: MatchRecord

  var body: some View {
    let score = record.score
    VStack(alignment: .leading, spacing: 8) {
      if let winner = score.winner {
        Text("\(record.setup.teamNames[winner]) won")
          .font(.headline)
          .foregroundStyle(Theme.color(winner))
        Text(formatSets(score.completedSets, from: winner))
          .font(.title3.weight(.bold))
          .monospacedDigit()
      } else {
        ForEach(Team.allCases, id: \.self) { team in
          HStack(spacing: 10) {
            Circle()
              .fill(score.server == team ? Theme.accent : .clear)
              .frame(width: 8, height: 8)
            Text(record.setup.teamNames[team])
              .foregroundStyle(Theme.color(team))
              .lineLimit(1)
            Spacer()
            ForEach(Array(score.completedSets.enumerated()), id: \.offset) { _, set in
              Text("\(set.games[team])").foregroundStyle(.secondary)
            }
            Text("\(score.currentSet[team])").foregroundStyle(Theme.accent)
            Text(points(score, team))
              .frame(minWidth: 36, alignment: .trailing)
          }
          .font(.headline)
          .monospacedDigit()
        }
      }
    }
    .padding(.vertical, 4)
  }

  private func points(_ score: MatchScore, _ team: Team) -> String {
    switch score.currentGame {
    case .regular(let display): return display[team]
    case .tiebreak(let points): return String(points[team])
    }
  }
}
