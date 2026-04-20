import Foundation

struct DelegatedItem: Identifiable {
    let id = UUID()
    var title: String
    var person: String
    var date = Date()
    var isDone = false
}
