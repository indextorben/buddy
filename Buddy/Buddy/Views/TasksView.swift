//
//  TasksView.swift
//  Buddy
//
//  Created by Torben Lehneke on 19.04.26.
//

import SwiftUI

// MARK: - Full Sheet View

struct TasksView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("accentColorHex") private var accentHex = "6C63FF"

    @State private var newTitle      = ""
    @State private var newPriority   = "Mittel"
    @State private var newHabitTitle = ""
    @State private var renamingTaskID:  UUID? = nil
    @State private var renamingHabitID: UUID? = nil
    @State private var renameText = ""
    @FocusState private var focused: Bool
    @FocusState private var habitFocused: Bool

    private let priorities = ["Hoch", "Mittel", "Niedrig"]
    private static let priorityColor: [String: String] = [
        "Hoch": "EF4444", "Mittel": "F97316", "Niedrig": "10B981"
    ]

    var body: some View {
        NavigationView {
            List {
                // ── Aufgaben ───────────────────────────────────
                Section {
                    if viewModel.tasks.isEmpty {
                        emptyState(text: "Keine Aufgaben", icon: "checkmark.circle")
                            .listRowBackground(Color(.secondarySystemGroupedBackground))
                    } else {
                        ForEach(viewModel.tasks) { task in
                            TaskCardView(task: task) { viewModel.toggleTask(task) }
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color(.secondarySystemGroupedBackground))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        withAnimation { viewModel.tasks.removeAll { $0.id == task.id } }
                                    } label: { Label("Löschen", systemImage: "trash") }

                                    Button {
                                        renameText = task.title
                                        renamingTaskID = task.id
                                    } label: { Label("Umbenennen", systemImage: "paintbrush") }
                                        .tint(Color(hex: accentHex))
                                }
                        }
                    }
                    addCard
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color(.systemGroupedBackground))
                } header: {
                    sectionHeader("Aufgaben", icon: "checkmark.circle.fill", color: Color(hex: accentHex))
                        .textCase(nil)
                }

                // ── Habits ─────────────────────────────────────
                Section {
                    if viewModel.habits.isEmpty {
                        emptyState(text: "Keine Habits", icon: "flame")
                            .listRowBackground(Color(.secondarySystemGroupedBackground))
                    } else {
                        ForEach(viewModel.habits) { habit in
                            HabitCardView(habit: habit) { viewModel.toggleHabit(habit) }
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color(.secondarySystemGroupedBackground))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        withAnimation { viewModel.habits.removeAll { $0.id == habit.id } }
                                    } label: { Label("Löschen", systemImage: "trash") }

                                    Button {
                                        renameText = habit.title
                                        renamingHabitID = habit.id
                                    } label: { Label("Umbenennen", systemImage: "paintbrush") }
                                        .tint(Color(hex: "FF6584"))
                                }
                        }
                    }
                    addHabitCard
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color(.systemGroupedBackground))
                } header: {
                    sectionHeader("Habits", icon: "flame.fill", color: Color(hex: "FF6584"))
                        .textCase(nil)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Heute")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: accentHex))
                }
            }
            .alert("Aufgabe umbenennen", isPresented: Binding(
                get: { renamingTaskID != nil },
                set: { if !$0 { renamingTaskID = nil } }
            )) {
                TextField("Name", text: $renameText)
                Button("Speichern") {
                    if let id = renamingTaskID,
                       let i = viewModel.tasks.firstIndex(where: { $0.id == id }) {
                        viewModel.tasks[i].title = renameText
                    }
                    renamingTaskID = nil
                }
                Button("Abbrechen", role: .cancel) { renamingTaskID = nil }
            }
            .alert("Habit umbenennen", isPresented: Binding(
                get: { renamingHabitID != nil },
                set: { if !$0 { renamingHabitID = nil } }
            )) {
                TextField("Name", text: $renameText)
                Button("Speichern") {
                    if let id = renamingHabitID,
                       let i = viewModel.habits.firstIndex(where: { $0.id == id }) {
                        viewModel.habits[i].title = renameText
                    }
                    renamingHabitID = nil
                }
                Button("Abbrechen", role: .cancel) { renamingHabitID = nil }
            }
        }
    }

    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 14, weight: .semibold))
            Text(title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            Spacer()
        }
    }

    private func emptyState(text: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.secondary.opacity(0.4))
                .font(.system(size: 20))
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 4)
    }

    private var addCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: accentHex))
                TextField("Neue Aufgabe…", text: $newTitle)
                    .font(.system(size: 16, weight: .medium))
                    .focused($focused)
                    .submitLabel(.done)
                    .onSubmit { addTask() }
            }

            HStack(spacing: 8) {
                ForEach(priorities, id: \.self) { p in
                    let hex = Self.priorityColor[p] ?? accentHex
                    Button {
                        withAnimation(.spring(response: 0.3)) { newPriority = p }
                    } label: {
                        Text(p)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(newPriority == p ? .white : Color(hex: hex))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(
                                newPriority == p ? Color(hex: hex) : Color(hex: hex).opacity(0.12)
                            ))
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }

            Button(action: addTask) {
                Label("Hinzufügen", systemImage: "plus")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .fill(newTitle.trimmingCharacters(in: .whitespaces).isEmpty
                                  ? Color(hex: accentHex).opacity(0.3)
                                  : Color(hex: accentHex))
                    )
            }
            .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private var addHabitCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "FF6584"))
                TextField("Neuer Habit…", text: $newHabitTitle)
                    .font(.system(size: 16, weight: .medium))
                    .focused($habitFocused)
                    .submitLabel(.done)
                    .onSubmit { addHabit() }
            }
            Button(action: addHabit) {
                Label("Hinzufügen", systemImage: "plus")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .fill(newHabitTitle.trimmingCharacters(in: .whitespaces).isEmpty
                                  ? Color(hex: "FF6584").opacity(0.3)
                                  : Color(hex: "FF6584"))
                    )
            }
            .disabled(newHabitTitle.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color(.secondarySystemGroupedBackground)))
    }

    private func addHabit() {
        let t = newHabitTitle.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        withAnimation { viewModel.habits.append(Habit(title: t, isDone: false)) }
        newHabitTitle = ""
        habitFocused  = false
    }

    private func addTask() {
        let t = newTitle.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        withAnimation { viewModel.tasks.append(Task(title: t, isDone: false, priority: newPriority)) }
        newTitle    = ""
        newPriority = "Mittel"
        focused     = false
    }
}

// MARK: - Card (inline in HomeView)

struct TaskCardView: View {
    let task: Task
    let onToggle: () -> Void

    private static let priorityColor: [String: String] = [
        "Hoch": "EF4444", "Mittel": "F97316", "Niedrig": "10B981"
    ]

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onToggle) {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(task.isDone ? Color(hex: "6C63FF") : Color(.tertiaryLabel))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(task.isDone ? .secondary : .primary)
                    .strikethrough(task.isDone, color: .secondary)

                HStack(spacing: 5) {
                    let hex = Self.priorityColor[task.priority] ?? "6C63FF"
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: 6, height: 6)
                    Text(task.priority)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}
