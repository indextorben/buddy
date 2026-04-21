//
//  ShoppingView.swift
//  Buddy

import SwiftUI

struct ShoppingView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var newTitle = ""
    @FocusState private var focused: Bool

    private var open: [ShoppingItem]  { viewModel.shoppingItems.filter { !$0.isDone } }
    private var done: [ShoppingItem]  { viewModel.shoppingItems.filter {  $0.isDone } }

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack(spacing: 10) {
                        Button(action: add) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20)).foregroundColor(Color(hex: "EC4899"))
                        }
                        .buttonStyle(.plain)
                        TextField("Artikel hinzufügen…", text: $newTitle)
                            .font(.system(size: 16)).focused($focused)
                            .submitLabel(.done).onSubmit(add)
                    }
                    .padding(.vertical, 4)
                }

                if !open.isEmpty {
                    Section("Offen") {
                        ForEach(open) { item in row(item) }
                    }
                }

                if !done.isEmpty {
                    Section("Erledigt") {
                        ForEach(done) { item in row(item) }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Einkaufsliste")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !done.isEmpty {
                        Button("Leeren") {
                            withAnimation { viewModel.shoppingItems.removeAll { $0.isDone } }
                        }
                        .foregroundColor(.secondary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .fontWeight(.semibold).foregroundColor(Color(hex: "EC4899"))
                }
            }
        }
    }

    @ViewBuilder private func row(_ item: ShoppingItem) -> some View {
        HStack(spacing: 12) {
            Button {
                if let i = viewModel.shoppingItems.firstIndex(where: { $0.id == item.id }) {
                    withAnimation { viewModel.shoppingItems[i].isDone.toggle() }
                }
            } label: {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(item.isDone ? Color(hex: "EC4899") : Color(.tertiaryLabel))
            }
            .buttonStyle(.plain)
            Text(item.title)
                .font(.system(size: 15))
                .foregroundColor(item.isDone ? .secondary : .primary)
                .strikethrough(item.isDone, color: .secondary)
            Spacer()
        }
        .padding(.vertical, 3)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                viewModel.shoppingItems.removeAll { $0.id == item.id }
            } label: { Label("Löschen", systemImage: "trash") }
        }
    }

    private func add() {
        let t = newTitle.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        withAnimation { viewModel.shoppingItems.append(ShoppingItem(title: t)) }
        newTitle = ""
    }
}
