//
//  HabitEditView.swift
//  Buddy
//
//  Created by Torben Lehneke on 19.04.26.
//

import SwiftUI

struct HabitEditView: View {
    @Binding var habits: [Habit]
    @Environment(\.dismiss) private var dismiss
    @State private var newTitle = ""

    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach($habits) { $habit in
                        HStack {
                            Image(systemName: habit.isDone ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(habit.isDone ? Color(hex: "FF6584") : .gray)
                            TextField("Habit", text: $habit.title)
                        }
                    }
                    .onDelete { habits.remove(atOffsets: $0) }
                    .onMove  { habits.move(fromOffsets: $0, toOffset: $1) }
                } header: {
                    Text("Deine Habits")
                }

                Section {
                    HStack {
                        TextField("Neuer Habit…", text: $newTitle)
                        Button {
                            let trimmed = newTitle.trimmingCharacters(in: .whitespaces)
                            guard !trimmed.isEmpty else { return }
                            habits.append(Habit(title: trimmed, isDone: false))
                            newTitle = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(Color(hex: "FF6584"))
                                .font(.title3)
                        }
                    }
                } header: {
                    Text("Hinzufügen")
                }
            }
            .navigationTitle("Habits bearbeiten")
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

