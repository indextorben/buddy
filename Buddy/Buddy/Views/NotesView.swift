//
//  NotesView.swift
//  Buddy

import SwiftUI

struct NotesView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var newText = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20)).foregroundColor(Color(hex: "F97316"))
                        TextField("Neue Notiz…", text: $newText, axis: .vertical)
                            .font(.system(size: 15)).focused($focused).lineLimit(2...5)
                        Button(action: add) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(
                                    newText.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? Color(hex: "F97316").opacity(0.3) : Color(hex: "F97316")
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(newText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.vertical, 4)
                }

                Section("Meine Notizen") {
                    if viewModel.notes.isEmpty {
                        Text("Noch keine Notizen")
                            .foregroundColor(.secondary).font(.subheadline)
                    } else {
                        ForEach(viewModel.notes) { note in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(note.text).font(.system(size: 15))
                                Text(note.createdAt, style: .relative)
                                    .font(.system(size: 12)).foregroundColor(.secondary)
                            }
                            .padding(.vertical, 3)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.notes.removeAll { $0.id == note.id }
                                } label: { Label("Löschen", systemImage: "trash") }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Notizen")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .fontWeight(.semibold).foregroundColor(Color(hex: "F97316"))
                }
            }
        }
    }

    private func add() {
        let t = newText.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        withAnimation { viewModel.notes.insert(Note(text: t), at: 0) }
        newText = ""; focused = false
    }
}
