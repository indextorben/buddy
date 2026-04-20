import Foundation

struct Idea: Identifiable {
    let id = UUID()
    var text: String
    var isStarred = false
    var date = Date()
}
