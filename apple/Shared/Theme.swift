import PadelScoreKit
import SwiftUI

enum Theme {
  static let accent = Color(red: 0xFA / 255, green: 0xCC / 255, blue: 0x15 / 255)

  static func color(_ team: Team) -> Color {
    switch team {
    case .a: return Color(red: 0x0D / 255, green: 0x94 / 255, blue: 0x88 / 255)  // teal
    case .b: return Color(red: 0x9B / 255, green: 0x7B / 255, blue: 0xD4 / 255)  // lilac
    }
  }
}

extension DeuceRule {
  var label: String {
    switch self {
    case .advantage: return "Advantage"
    case .golden: return "Golden point"
    case .star: return "Star point"
    }
  }

  /// Short name for segmented pickers.
  var shortLabel: String {
    switch self {
    case .advantage: return "Advantage"
    case .golden: return "Golden"
    case .star: return "Star"
    }
  }

  var explanation: String {
    switch self {
    case .advantage:
      return "At 40–40 a team must win two points in a row. Can go on for a long time."
    case .golden:
      return "At 40–40 the next point wins the game."
    case .star:
      return "Advantage at the first two deuces. At the third 40–40, the next point wins."
    }
  }
}
