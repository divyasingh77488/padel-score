import Foundation
import PadelScoreKit

extension Booking {
  /// "Sat 11 Oct, 18:00 · Club X", or "Today, 18:00 · Club X".
  var summary: String {
    "\(Booking.dayAndTime(start)) · \(placeOrTitle)"
  }

  static func dayAndTime(_ date: Date) -> String {
    let time = date.formatted(date: .omitted, time: .shortened)
    let calendar = Calendar.current
    if calendar.isDateInToday(date) { return "Today, \(time)" }
    if calendar.isDateInTomorrow(date) { return "Tomorrow, \(time)" }
    let day = date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    return "\(day), \(time)"
  }
}
