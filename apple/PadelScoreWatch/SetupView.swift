import PadelScoreKit
import SwiftUI

struct SetupView: View {
  @ObservedObject var model: MatchModel
  @ObservedObject private var sync = SyncSession.shared

  @State private var nameA = ""
  @State private var nameB = ""
  @State private var firstServer: Team = .a
  @State private var deuceRule: DeuceRule = .golden
  @State private var loaded = false

  var body: some View {
    List {
      if let match = model.next {
        Section("From your phone") {
          Button {
            model.startNext()
          } label: {
            VStack(alignment: .leading, spacing: 2) {
              Text(match.setup.teamNames.a)
                .foregroundStyle(Theme.color(.a))
                + Text(" vs ").foregroundStyle(.secondary)
                + Text(match.setup.teamNames.b)
                .foregroundStyle(Theme.color(.b))
              Text("\(match.setup.deuceRule.label) · Tap to start")
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .font(.headline)
          }
        }
      }

      if model.next == nil {
        Section {
          Button {
            model.checkPhone()
          } label: {
            Label("Check phone for a match", systemImage: "iphone.and.arrow.forward")
          }
        } footer: {
          if let check = sync.phoneCheck {
            Text(check)
          }
        }
      }

      Section(model.next == nil ? "Teams" : "Or set up here") {
        TextField("Team 1", text: $nameA)
          .foregroundStyle(Theme.color(.a))
        TextField("Team 2", text: $nameB)
          .foregroundStyle(Theme.color(.b))
      }

      Picker("Serves first", selection: $firstServer) {
        Text(name(.a)).tag(Team.a)
        Text(name(.b)).tag(Team.b)
      }

      Section {
        Picker("At 40–40", selection: $deuceRule) {
          ForEach(DeuceRule.allCases, id: \.self) { rule in
            Text(rule.label).tag(rule)
          }
        }
        NavigationLink {
          DeuceRuleInfoView(selected: deuceRule)
        } label: {
          Label("What do these mean?", systemImage: "info.circle")
        }
      }

      Button {
        model.startMatch(
          MatchSetup(
            teamNames: PerTeam(a: name(.a), b: name(.b)),
            firstServer: firstServer,
            deuceRule: deuceRule))
      } label: {
        Text("Start match")
          .font(.headline)
          .frame(maxWidth: .infinity)
      }
      .listRowBackground(Theme.accent)
      .foregroundStyle(.black)
    }
    .navigationTitle("Padel Battle")
    .onAppear {
      guard !loaded else { return }
      loaded = true
      let last = model.lastSetup
      nameA = last.teamNames.a
      nameB = last.teamNames.b
      firstServer = last.firstServer
      deuceRule = last.deuceRule
    }
  }

  private func name(_ team: Team) -> String {
    let typed = (team == .a ? nameA : nameB).trimmingCharacters(in: .whitespaces)
    return typed.isEmpty ? (team == .a ? "Us" : "Them") : typed
  }
}

struct DeuceRuleInfoView: View {
  let selected: DeuceRule

  var body: some View {
    List(DeuceRule.allCases, id: \.self) { rule in
      VStack(alignment: .leading, spacing: 4) {
        Text(rule.label)
          .font(.headline)
          .foregroundStyle(rule == selected ? Theme.accent : .primary)
        Text(rule.explanation)
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
      .padding(.vertical, 4)
    }
    .navigationTitle("At 40–40")
  }
}
