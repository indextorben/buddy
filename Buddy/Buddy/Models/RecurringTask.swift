import Foundation

enum Recurrence: String, CaseIterable, Identifiable, Codable {
    case daily     = "Täglich"
    case weekdays  = "Mo–Fr"
    case weekends  = "Sa–So"
    case monday    = "Montags"
    case tuesday   = "Dienstags"
    case wednesday = "Mittwochs"
    case thursday  = "Donnerstags"
    case friday    = "Freitags"
    case saturday  = "Samstags"
    case sunday    = "Sonntags"

    var id: String { rawValue }

    var isDueToday: Bool {
        let wd = Calendar.current.component(.weekday, from: Date()) // 1=So,2=Mo,...
        switch self {
        case .daily:     return true
        case .weekdays:  return (2...6).contains(wd)
        case .weekends:  return wd == 1 || wd == 7
        case .monday:    return wd == 2
        case .tuesday:   return wd == 3
        case .wednesday: return wd == 4
        case .thursday:  return wd == 5
        case .friday:    return wd == 6
        case .saturday:  return wd == 7
        case .sunday:    return wd == 1
        }
    }
}

enum RoutineTime: String, CaseIterable, Identifiable, Codable {
    case morning  = "Morgen"
    case midday   = "Mittags"
    case evening  = "Abend"
    case anytime  = "Jederzeit"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .midday:  return "sun.max.fill"
        case .evening: return "moon.fill"
        case .anytime: return "clock"
        }
    }
}

struct RecurringTask: Identifiable, Codable {
    var id = UUID()
    var title: String
    var recurrence: Recurrence
    var time: RoutineTime = .anytime
    var lastDoneDate: Date?

    var isDueToday: Bool { recurrence.isDueToday }
    var isDoneToday: Bool {
        guard let d = lastDoneDate else { return false }
        return Calendar.current.isDateInToday(d)
    }
}
