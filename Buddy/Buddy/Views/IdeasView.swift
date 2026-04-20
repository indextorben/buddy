//  IdeasView.swift
import SwiftUI

struct IdeasView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var newText = ""
    @FocusState private var focused: Bool

    private var starred: [Idea] { viewModel.ideas.filter {  $0.isStarred } }
    private var rest:    [Idea] { viewModel.ideas.filter { !$0.isStarred } }

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20)).foregroundColor(Color(hex: "FBBF24"))
                        TextField("Neue Idee…", text: $newText, axis: .vertical)
                            .font(.system(size: 15)).focused($focused).lineLimit(2...4)
                        Button(action: add) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(newText.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? Color(hex: "FBBF24").opacity(0.3) : Color(hex: "FBBF24"))
                        }
                        .buttonStyle(.plain)
                        .disabled(newText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }.padding(.vertical, 4)
                }

                if !starred.isEmpty {
                    Section("Favoriten ⭐") { ForEach(starred) { ideaRow($0) } }
                }
                if !rest.isEmpty {
                    Section("Alle Ideen") { ForEach(rest) { ideaRow($0) } }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Ideen")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .fontWeight(.semibold).foregroundColor(Color(hex: "FBBF24"))
                }
            }
        }
    }

    @ViewBuilder private func ideaRow(_ idea: Idea) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Button {
                if let i = viewModel.ideas.firstIndex(where: { $0.id == idea.id }) {
                    withAnimation { viewModel.ideas[i].isStarred.toggle() }
                }
            } label: {
                Image(systemName: idea.isStarred ? "star.fill" : "star")
                    .font(.system(size: 16))
                    .foregroundColor(idea.isStarred ? Color(hex: "FBBF24") : Color(.tertiaryLabel))
            }.buttonStyle(.plain)
            Text(idea.text).font(.system(size: 15))
            Spacer()
        }
        .padding(.vertical, 3)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                viewModel.ideas.removeAll { $0.id == idea.id }
            } label: { Label("Löschen", systemImage: "trash") }
        }
    }

    private func add() {
        let t = newText.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        withAnimation { viewModel.ideas.insert(Idea(text: t), at: 0) }
        newText = ""; focused = false
    }
}
