//
//  TaskEditView.swift
//  Buddy
//
//  Created by Torben Lehneke on 19.04.26.
//

import SwiftUI

struct TaskEditView: View {
    @Binding var tasks: [Task]
    @Environment(\.dismiss) private var dismiss
    @State private var newTitle = ""
    @State private var newPriority = "Mittel"

    private let priorities = ["Hoch", "Mittel", "Niedrig"]

    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach($tasks) { $task in
                        HStack {
                            Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(task.isDone ? Color(hex: "6C63FF") : .gray)
                            VStack(alignment: .leading, spacing: 2) {
                                TextField("Aufgabe", text: $task.title)
                                    .font(.body)
                                Picker("", selection: $task.priority) {
                                    ForEach(priorities, id: \.self) { Text($0) }
                                }
                                .pickerStyle(.segmented)
                                .labelsHidden()
                            }
                        }
                    }
                    .onDelete { tasks.remove(atOffsets: $0) }
                    .onMove  { tasks.move(fromOffsets: $0, toOffset: $1) }
                } header: {
                    Text("Deine Aufgaben")
                }

                Section {
                    TextField("Neue Aufgabe…", text: $newTitle)
                    Picker("Priorität", selection: $newPriority) {
                        ForEach(priorities, id: \.self) { Text($0) }
                    }
                    Button {
                        let trimmed = newTitle.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        tasks.append(Task(title: trimmed, isDone: false, priority: newPriority))
                        newTitle = ""
                        newPriority = "Mittel"
                    } label: {
                        Label("Hinzufügen", systemImage: "plus.circle.fill")
                            .foregroundColor(Color(hex: "6C63FF"))
                    }
                } header: {
                    Text("Hinzufügen")
                }
            }
            .navigationTitle("Aufgaben bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
