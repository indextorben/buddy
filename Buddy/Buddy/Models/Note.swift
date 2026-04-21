import Foundation

struct Note: Identifiable, Codable {
    var id = UUID()
    var text: String
    var createdAt = Date()
}
