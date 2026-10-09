import PadelScoreKit
import SwiftUI

struct NewMatchView: View {
  @ObservedObject var store: PhoneStore
  @Environment(\.dismiss) private var dismiss

  @State private var nameA = ""
  @State private var nameB = ""
  @State private var firstServer: Team = .a
  @State private var deuceRule: DeuceRule = .golden
  @State private var loaded = false

  var body: some View {
    NavigationStack {
      Form {
        Section("Teams") {
          TextField("Team A", text: $nameA)
            .foregroundStyle(Theme.color(.a))
          TextField("Team B", text: $nameB)
            .foregroundStyle(Theme.color(.b))
        }

        Section("Serves first") {
          Picker("Serves first", selection: $firstServer) {
            Text(name(.a)).tag(Team.a)
            Text(name(.b)).tag(Team.b)
          }
          .pickerStyle(.segmented)
        }

        Section("At 40–40") {
          Picker("At 40–40", selection: $deuceRule) {
            ForEach(DeuceRule.allCases, id: \.self) { rule in
              Text(rule.shortLabel).tag(rule)
            }
          }
          .pickerStyle(.segmented)
          DisclosureGroup {
            ForEach(DeuceRule.allCases, id: \.self) { rule in
              VStack(alignment: .leading, spacing: 2) {
                Text(rule.label)
                  .font(.subheadline.weight(.semibold))
                  .foregroundStyle(rule == deuceRule ? Theme.accent : .primary)
                Text(rule.explanation)
                  .font(.footnote)
                  .foregroundStyle(.secondary)
              }
            }
          } label: {
            Label("What do these mean?", systemImage: "info.circle")
          }
        }

        Section {
          Button {
            store.sendToWatch(setup)
            dismiss()
          } label: {
            Label("Send to watch", systemImage: "applewatch")
              .font(.headline)
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.borderedProminent)
          .tint(Theme.accent)
          .foregroundStyle(.black)
          .listRowBackground(Color.clear)

          Button {
            store.playOnPhone(setup)
            dismiss()
          } label: {
            Text("Play on phone now")
              .frame(maxWidth: .infinity)
          }
          .listRowBackground(Color.clear)
        }
      }
      .navigationTitle("New match")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
      }
      .onAppear {
        guard !loaded else { return }
        loaded = true
        let last = store.lastSetup
        nameA = last.teamNames.a
        nameB = last.teamNames.b
        firstServer = last.firstServer
        deuceRule = last.deuceRule
      }
    }
  }

  private var setup: MatchSetup {
    MatchSetup(
      teamNames: PerTeam(a: name(.a), b: name(.b)), firstServer: firstServer, deuceRule: deuceRule)
  }

  private func name(_ team: Team) -> String {
    let typed = (team == .a ? nameA : nameB).trimmingCharacters(in: .whitespaces)
    return typed.isEmpty ? (team == .a ? "Team A" : "Team B") : typed
  }
}
