import Foundation

struct Idea: Identifiable, Codable {
    var id = UUID()
    var text: String
    var isStarred = false
    var date = Date()
}
