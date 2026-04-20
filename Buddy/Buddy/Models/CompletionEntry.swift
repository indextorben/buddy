import Foundation

struct CompletionEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let title: String
    let type: EntryType

    enum EntryType: String, Codable { case habit, task }
}
