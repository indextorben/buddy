import Foundation

struct Note: Identifiable {
    let id = UUID()
    var text: String
    var createdAt = Date()
}
