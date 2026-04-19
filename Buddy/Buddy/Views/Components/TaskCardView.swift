//
//  TaskCardView.swift
//  Buddy
//
//  Created by Torben Lehneke on 19.04.26.
//

import SwiftUI

struct TaskCardView: View {
    let task: Task
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(task.isDone ? .green : .gray)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(task.isDone ? .secondary : .primary)
                    .strikethrough(task.isDone)

                Text("Priorität: \(task.priority)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    VStack(spacing: 12) {
        TaskCardView(
            task: Task(title: "Mathe lernen", isDone: false, priority: "Hoch"),
            onToggle: {}
        )

        TaskCardView(
            task: Task(title: "Zimmer aufräumen", isDone: true, priority: "Niedrig"),
            onToggle: {}
        )
    }
    .padding()
}
