import PadelScoreKit
import SwiftUI

struct HomeView: View {
  @ObservedObject var store: PhoneStore
  @ObservedObject private var sync = SyncSession.shared
  @State private var showNewMatch = false

  var body: some View {
    NavigationStack {
      List {
        Section {
          if let match = store.next {
            VStack(alignment: .leading, spacing: 10) {
              VStack(alignment: .leading, spacing: 2) {
                TeamsText(names: match.setup.teamNames)
                  .font(.title3.weight(.bold))
                Text(match.setup.deuceRule.label)
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
              if let problem = watchProblem {
                Label(problem, systemImage: "exclamationmark.triangle.fill")
                  .font(.caption)
                  .foregroundStyle(.yellow)
              }
              HStack {
                Button("Play on phone") { store.playNextOnPhone() }
                  .buttonStyle(.bordered)
                Button("Send again") { store.resendToWatch() }
                  .buttonStyle(.bordered)
                Spacer()
                Button("Remove", role: .destructive) { store.clearNext() }
                  .buttonStyle(.borderless)
              }
              .font(.subheadline)
            }
            .padding(.vertical, 4)
          } else {
            Text("No match on your watch yet.")
              .foregroundStyle(.secondary)
          }
          Button {
            showNewMatch = true
          } label: {
            Label(
              store.next == nil ? "New match" : "Replace with a new match",
              systemImage: "plus.circle.fill"
            )
            .font(.headline)
          }
        } header: {
          Text("Next on your watch")
        } footer: {
          Text(
            store.next == nil
              ? "Set up a match here and it appears on your watch, ready to start."
              : "Open Padel Battle on your watch and tap the match to start it. The result comes back to History when the match ends."
          )
        }

        if store.next == nil, let problem = watchProblem {
          Section {
            Label(problem, systemImage: "exclamationmark.triangle.fill")
              .font(.caption)
              .foregroundStyle(.yellow)
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

extension HomeView {
  /// Why matches can't reach the watch right now, or nil when the link is fine.
  fileprivate var watchProblem: String? {
    switch sync.status {
    case .ready, .connecting: return nil
    case .noWatch: return "No Apple Watch is paired with this iPhone."
    case .watchAppMissing:
      return "Padel Battle isn't installed on your watch. Install it from the Watch app on this iPhone, or run the watch app from Xcode."
    case .failed(let message): return "Couldn't send to the watch: \(message)"
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
