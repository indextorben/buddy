//  BirthdaysView.swift
import SwiftUI

struct BirthdaysView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var newName = ""
    @State private var newDate = Date()
    @FocusState private var focused: Bool

    private var sorted: [Birthday] { viewModel.birthdays.sorted { $0.daysUntil < $1.daysUntil } }

    var body: some View {
        NavigationView {
            List {
                Section("Neuer Geburtstag") {
                    TextField("Name", text: $newName).focused($focused)
                    DatePicker("Datum", selection: $newDate, displayedComponents: [.date])
                    Button("Hinzufügen", action: add)
                        .foregroundColor(Color(hex: "F472B6"))
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                if !sorted.isEmpty {
                    Section("Geburtstage") {
                        ForEach(sorted) { b in
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(b.name).font(.system(size: 15, weight: .medium))
                                    Text(b.date.formatted(.dateTime.day().month(.wide)))
                                        .font(.system(size: 12)).foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(b.daysUntil == 0 ? "Heute 🎂" : "in \(b.daysUntil) Tagen")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(b.daysUntil <= 7 ? Color(hex: "F472B6") : .secondary)
                            }
                            .padding(.vertical, 3)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.birthdays.removeAll { $0.id == b.id }
                                } label: { Label("Löschen", systemImage: "trash") }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Geburtstage")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .fontWeight(.semibold).foregroundColor(Color(hex: "F472B6"))
                }
            }
        }
    }

    private func add() {
        let n = newName.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty else { return }
        withAnimation { viewModel.birthdays.append(Birthday(name: n, date: newDate)) }
        newName = ""; focused = false
    }
}
