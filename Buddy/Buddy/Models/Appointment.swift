import Foundation

struct Appointment: Identifiable {
    let id = UUID()
    var title: String
    var time: Date
}
