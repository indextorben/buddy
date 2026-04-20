//
//  DeadlinesView.swift
//  Buddy

import SwiftUI

struct DeadlinesView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var newTitle = ""
    @State private var newDate  = Date()
    @FocusState private var focused: Bool

    private var sorted: [Deadline] { viewModel.deadlines.sorted { $0.dueDate < $1.dueDate } }

    var body: some View {
        NavigationView {
            List {
                Section("Neue Frist") {
                    TextField("Titel", text: $newTitle).focused($focused)
                    DatePicker("Fällig am", selection: $newDate, displayedComponents: [.date, .hourAndMinute])
                    Button("Hinzufügen", action: add)
                        .foregroundColor(Color(hex: "EF4444"))
                        .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                if !sorted.isEmpty {
                    Section("Fristen") {
                        ForEach(sorted) { dl in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(dl.isOverdue ? Color(hex: "EF4444") : dl.isUrgent ? Color(hex: "F97316") : Color(hex: "10B981"))
                                    .frame(width: 8, height: 8)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(dl.title).font(.system(size: 15, weight: .medium))
                                    Text(dl.dueDate.formatted(date: .abbreviated, time: .shortened))
                                        .font(.system(size: 12)).foregroundColor(
                                            dl.isOverdue ? Color(hex: "EF4444") : .secondary
                                        )
                                }
                                Spacer()
                                if dl.isOverdue {
                                    Text("Überfällig")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8).padding(.vertical, 3)
                                        .background(Capsule().fill(Color(hex: "EF4444")))
                                } else if dl.isUrgent {
                                    Text("Bald")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8).padding(.vertical, 3)
                                        .background(Capsule().fill(Color(hex: "F97316")))
                                }
                            }
                            .padding(.vertical, 4)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.deadlines.removeAll { $0.id == dl.id }
                                } label: { Label("Löschen", systemImage: "trash") }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Fristen")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .fontWeight(.semibold).foregroundColor(Color(hex: "EF4444"))
                }
            }
        }
    }

    private func add() {
        let t = newTitle.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        withAnimation { viewModel.deadlines.append(Deadline(title: t, dueDate: newDate)) }
        newTitle = ""; focused = false
    }
}
