import Foundation

struct Birthday: Identifiable {
    let id = UUID()
    var name: String
    var date: Date

    var daysUntil: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var comps = cal.dateComponents([.month, .day], from: date)
        comps.year = cal.component(.year, from: today)
        var next = cal.date(from: comps) ?? date
        if next < today { next = cal.date(byAdding: .year, value: 1, to: next) ?? next }
        return cal.dateComponents([.day], from: today, to: next).day ?? 0
    }
}
