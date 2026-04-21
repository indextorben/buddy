import Foundation

enum ProjectStatus: String, CaseIterable, Codable {
    case open     = "Offen"
    case active   = "In Arbeit"
    case done     = "Fertig"
}

struct Project: Identifiable, Codable {
    var id = UUID()
    var title: String
    var status: ProjectStatus = .open
}
