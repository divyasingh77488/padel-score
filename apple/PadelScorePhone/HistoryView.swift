import PadelScoreKit
import SwiftUI

struct HistoryView: View {
  @ObservedObject var store: PhoneStore
  @State private var confirmClear = false

  var body: some View {
    List {
      if store.history.isEmpty {
        Text("No matches yet. Finished matches from the phone and the watch appear here.")
          .foregroundStyle(.secondary)
      }
      ForEach(store.history) { record in
        HistoryRow(record: record)
      }
      .onDelete { offsets in
        let ids = offsets.map { store.history[$0].id }
        ids.forEach(store.deleteHistory)
      }
    }
    .navigationTitle("History")
    .toolbar {
      if !store.history.isEmpty {
        Button("Clear") { confirmClear = true }
      }
    }
    .confirmationDialog("Delete all matches?", isPresented: $confirmClear, titleVisibility: .visible) {
      Button("Delete all", role: .destructive) { store.clearHistory() }
    }
  }
}

private struct HistoryRow: View {
  let record: MatchRecord

  var body: some View {
    let score = record.score
    VStack(alignment: .leading, spacing: 4) {
      Text((record.finishedAt ?? record.startedAt).formatted(date: .abbreviated, time: .shortened))
        .font(.caption)
        .foregroundStyle(.secondary)
      if let winner = score.winner {
        Text(record.setup.teamNames[winner]).foregroundStyle(Theme.color(winner))
          + Text(" beat ").foregroundStyle(.secondary)
          + Text(record.setup.teamNames[winner.other]).foregroundStyle(Theme.color(winner.other))
        HStack {
          Text(formatSets(score.completedSets, from: winner))
            .font(.title3.weight(.bold))
            .monospacedDigit()
          Spacer()
          Text(record.setup.deuceRule.label)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
    .font(.headline)
    .padding(.vertical, 2)
  }
}
