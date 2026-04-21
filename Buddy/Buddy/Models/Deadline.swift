import Foundation

struct Deadline: Identifiable, Codable {
    var id = UUID()
    var title: String
    var dueDate: Date

    var isOverdue: Bool { dueDate < Date() }
    var isUrgent: Bool { !isOverdue && dueDate.timeIntervalSinceNow < 60 * 60 * 72 }
}
