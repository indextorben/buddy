import Foundation

struct CalendarEvent: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let calendarTitle: String
    let colorHex: String

    var duration: Int { max(15, Int(endDate.timeIntervalSince(startDate) / 60)) }
}
