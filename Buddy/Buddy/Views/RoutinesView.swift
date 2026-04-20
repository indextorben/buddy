//  RoutinesView.swift
import SwiftUI

struct RoutinesView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("accentColorHex") private var accentHex = "6C63FF"

    @State private var newTitle      = ""
    @State private var newRecurrence = Recurrence.daily
    @State private var newTime       = RoutineTime.anytime
    @FocusState private var focused: Bool

    private let timeColor: [RoutineTime: String] = [
        .morning: "F59E0B", .midday: "F97316", .evening: "6366F1", .anytime: "9CA3AF"
    ]

    private var dueToday: [RecurringTask] {
        viewModel.recurringTasks.filter { $0.isDueToday }
            .sorted { $0.time.rawValue < $1.time.rawValue }
    }
    private var notToday: [RecurringTask] {
        viewModel.recurringTasks.filter { !$0.isDueToday }
    }

    var body: some View {
        NavigationView {
            List {
                // Add
                Section {
                    TextField("Neue Routine…", text: $newTitle).focused($focused)
                    Picker("Wiederholung", selection: $newRecurrence) {
                        ForEach(Recurrence.allCases) { r in Text(r.rawValue).tag(r) }
                    }
                    Picker("Zeitpunkt", selection: $newTime) {
                        ForEach(RoutineTime.allCases) { t in
                            Label(t.rawValue, systemImage: t.icon).tag(t)
                        }
                    }
                    Button("Hinzufügen", action: add)
                        .foregroundColor(Color(hex: accentHex))
                        .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                } header: { Text("Neue Routine") }

                // Today
                if !dueToday.isEmpty {
                    Section {
                        ForEach(dueToday) { task in
                            routineRow(task)
                        }
                    } header: {
                        HStack(spacing: 6) {
                            let done = dueToday.filter { $0.isDoneToday }.count
                            Text("Heute")
                            Spacer()
                            Text("\(done)/\(dueToday.count)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(hex: accentHex))
                        }
                    }
                }

                // Other days
                if !notToday.isEmpty {
                    Section("Andere Tage") {
                        ForEach(notToday) { task in routineRow(task) }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Routinen")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .fontWeight(.semibold).foregroundColor(Color(hex: accentHex))
                }
            }
        }
    }

    @ViewBuilder
    private func routineRow(_ task: RecurringTask) -> some View {
        HStack(spacing: 12) {
            Button {
                if let i = viewModel.recurringTasks.firstIndex(where: { $0.id == task.id }) {
                    withAnimation {
                        viewModel.recurringTasks[i].lastDoneDate = task.isDoneToday ? nil : Date()
                    }
                }
            } label: {
                Image(systemName: task.isDoneToday ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(task.isDoneToday ? Color(hex: accentHex) : Color(.tertiaryLabel))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(task.isDoneToday ? .secondary : .primary)
                    .strikethrough(task.isDoneToday, color: .secondary)
                HStack(spacing: 6) {
                    Image(systemName: task.time.icon)
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: timeColor[task.time] ?? "9CA3AF"))
                    Text("\(task.time.rawValue) · \(task.recurrence.rawValue)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 3)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                viewModel.recurringTasks.removeAll { $0.id == task.id }
            } label: { Label("Löschen", systemImage: "trash") }
        }
    }

    private func add() {
        let t = newTitle.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        withAnimation {
            viewModel.recurringTasks.append(
                RecurringTask(title: t, recurrence: newRecurrence, time: newTime)
            )
        }
        newTitle = ""; focused = false
    }
}
