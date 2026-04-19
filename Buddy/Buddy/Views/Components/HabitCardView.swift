//
//  HabitCardView.swift
//  Buddy
//
//  Created by Torben Lehneke on 19.04.26.
//

import SwiftUI

struct HabitCardView: View {
    let habit: Habit
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: habit.isDone ? "checkmark.square.fill" : "square")
                    .font(.title2)
                    .foregroundColor(habit.isDone ? .green : .gray)
            }
            .buttonStyle(.plain)

            Text(habit.title)
                .font(.headline)
                .foregroundColor(habit.isDone ? .secondary : .primary)
                .strikethrough(habit.isDone)

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    VStack(spacing: 12) {
        HabitCardView(
            habit: Habit(title: "2L Wasser trinken", isDone: false),
            onToggle: {}
        )

        HabitCardView(
            habit: Habit(title: "10 Minuten lesen", isDone: true),
            onToggle: {}
        )
    }
    .padding()
}
