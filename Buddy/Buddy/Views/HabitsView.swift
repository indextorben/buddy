//
//  HabitsView.swift
//  Buddy
//
//  Created by Torben Lehneke on 19.04.26.
//

import SwiftUI

// MARK: - Full Sheet View

struct HabitsView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("accentColorHex") private var accentHex = "FF6584"

    @State private var newTitle = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {

                        if viewModel.habits.isEmpty {
                            emptyState
                        } else {
                            ForEach(viewModel.habits) { habit in
                                HabitCardView(habit: habit) { viewModel.toggleHabit(habit) }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            withAnimation {
                                                viewModel.habits.removeAll { $0.id == habit.id }
                                            }
                                        } label: {
                                            Label("Löschen", systemImage: "trash")
                                        }
                                    }
                            }
                        }

                        addCard
                        Spacer().frame(height: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Habits")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "FF6584"))
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "flame.fill")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "FF6584").opacity(0.3))
            Text("Keine Habits")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)
            Text("Füge deinen ersten Habit hinzu.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var addCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "FF6584"))
                TextField("Neuer Habit…", text: $newTitle)
                    .font(.system(size: 16, weight: .medium))
                    .focused($focused)
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
                            .fill(newTitle.trimmingCharacters(in: .whitespaces).isEmpty
                                  ? Color(hex: "FF6584").opacity(0.3)
                                  : Color(hex: "FF6584"))
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

    private func addHabit() {
        let t = newTitle.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        withAnimation { viewModel.habits.append(Habit(title: t, isDone: false)) }
        newTitle = ""
        focused  = false
    }
}

// MARK: - Card (inline in HomeView)

struct HabitCardView: View {
    let habit: Habit
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onToggle) {
                Image(systemName: habit.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(habit.isDone ? Color(hex: "FF6584") : Color(.tertiaryLabel))
            }
            .buttonStyle(.plain)

            Text(habit.title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(habit.isDone ? .secondary : .primary)
                .strikethrough(habit.isDone, color: .secondary)

            Spacer()

            if habit.isDone {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "FF6584"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}
