import Foundation

struct ShoppingItem: Identifiable {
    let id = UUID()
    var title: String
    var isDone = false
}
