//  ProjectsView.swift
import SwiftUI

struct ProjectsView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var newTitle = ""
    @FocusState private var focused: Bool

    private let statusColor: [ProjectStatus: String] = [
        .open: "9CA3AF", .active: "3B82F6", .done: "10B981"
    ]

    var body: some View {
        NavigationView {
            List {
                Section("Neues Projekt") {
                    TextField("Titel", text: $newTitle).focused($focused).submitLabel(.done).onSubmit(add)
                    Button("Hinzufügen", action: add)
                        .foregroundColor(Color(hex: "6366F1"))
                        .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                ForEach(ProjectStatus.allCases, id: \.self) { status in
                    let items = viewModel.projects.filter { $0.status == status }
                    if !items.isEmpty {
                        Section(status.rawValue) {
                            ForEach(items) { p in
                                HStack {
                                    Circle().fill(Color(hex: statusColor[status] ?? "9CA3AF")).frame(width: 8, height: 8)
                                    Text(p.title).font(.system(size: 15, weight: .medium))
                                    Spacer()
                                    Menu {
                                        ForEach(ProjectStatus.allCases, id: \.self) { s in
                                            Button(s.rawValue) {
                                                if let i = viewModel.projects.firstIndex(where: { $0.id == p.id }) {
                                                    withAnimation { viewModel.projects[i].status = s }
                                                }
                                            }
                                        }
                                    } label: {
                                        Text(status.rawValue)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8).padding(.vertical, 3)
                                            .background(Capsule().fill(Color(hex: statusColor[status] ?? "9CA3AF")))
                                    }
                                }
                                .padding(.vertical, 3)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        viewModel.projects.removeAll { $0.id == p.id }
                                    } label: { Label("Löschen", systemImage: "trash") }
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Projekte")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .fontWeight(.semibold).foregroundColor(Color(hex: "6366F1"))
                }
            }
        }
    }

    private func add() {
        let t = newTitle.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        withAnimation { viewModel.projects.append(Project(title: t)) }
        newTitle = ""; focused = false
    }
}
