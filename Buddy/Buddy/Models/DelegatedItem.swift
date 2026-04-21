import Foundation

struct DelegatedItem: Identifiable, Codable {
    var id = UUID()
    var title: String
    var person: String
    var date = Date()
    var isDone = false
}
