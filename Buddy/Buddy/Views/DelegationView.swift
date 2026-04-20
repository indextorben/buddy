//
//  DelegationView.swift
//  Buddy

import SwiftUI

struct DelegationView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var newTitle  = ""
    @State private var newPerson = ""
    @FocusState private var focused: Bool

    private var open: [DelegatedItem] { viewModel.delegatedItems.filter { !$0.isDone } }
    private var done: [DelegatedItem] { viewModel.delegatedItems.filter {  $0.isDone } }

    var body: some View {
        NavigationView {
            List {
                Section("Neu delegieren") {
                    TextField("Aufgabe", text: $newTitle).focused($focused)
                    TextField("An wen?", text: $newPerson)
                    Button("Hinzufügen", action: add)
                        .foregroundColor(Color(hex: "8B5CF6"))
                        .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty ||
                                  newPerson.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                if !open.isEmpty {
                    Section("Offen") { ForEach(open) { row($0) } }
                }
                if !done.isEmpty {
                    Section("Erledigt") { ForEach(done) { row($0) } }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Delegiert")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .fontWeight(.semibold).foregroundColor(Color(hex: "8B5CF6"))
                }
            }
        }
    }

    @ViewBuilder private func row(_ item: DelegatedItem) -> some View {
        HStack(spacing: 12) {
            Button {
                if let i = viewModel.delegatedItems.firstIndex(where: { $0.id == item.id }) {
                    withAnimation { viewModel.delegatedItems[i].isDone.toggle() }
                }
            } label: {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(item.isDone ? Color(hex: "8B5CF6") : Color(.tertiaryLabel))
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(item.isDone ? .secondary : .primary)
                    .strikethrough(item.isDone, color: .secondary)
                HStack(spacing: 4) {
                    Image(systemName: "person.fill").font(.system(size: 10))
                    Text(item.person).font(.system(size: 12))
                }
                .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 3)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                viewModel.delegatedItems.removeAll { $0.id == item.id }
            } label: { Label("Löschen", systemImage: "trash") }
        }
    }

    private func add() {
        let t = newTitle.trimmingCharacters(in: .whitespaces)
        let p = newPerson.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty, !p.isEmpty else { return }
        withAnimation { viewModel.delegatedItems.append(DelegatedItem(title: t, person: p)) }
        newTitle = ""; newPerson = ""; focused = false
    }
}
