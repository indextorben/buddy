import Foundation

enum ProjectStatus: String, CaseIterable {
    case open     = "Offen"
    case active   = "In Arbeit"
    case done     = "Fertig"
}

struct Project: Identifiable {
    let id = UUID()
    var title: String
    var status: ProjectStatus = .open
}
