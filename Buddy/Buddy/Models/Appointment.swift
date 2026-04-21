import Foundation

struct Appointment: Identifiable, Codable {
    var id = UUID()
    var title: String
    var time: Date
}
