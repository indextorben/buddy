import Foundation

enum DayPlanType: String {
    case task        = "Aufgabe"
    case habit       = "Habit"
    case appointment = "Termin"
    case pause       = "Pause"
}

struct DayPlanItem: Identifiable {
    let id = UUID()
    var startTime: Date
    var duration: Int          // Minuten
    var title: String
    var type: DayPlanType
    var priority: String?      // nur bei .task
    var isDone = false

    var endTime: Date { startTime.addingTimeInterval(Double(duration) * 60) }
}
