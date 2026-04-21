import Foundation

struct ShoppingItem: Identifiable, Codable {
    var id = UUID()
    var title: String
    var isDone = false
}
