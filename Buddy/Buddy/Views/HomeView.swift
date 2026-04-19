//
//  HomeView.swift
//  Buddy
//
//  Created by Torben Lehneke on 19.04.26.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    DayOverviewView(
                        openTasksCount: viewModel.openTasksCount,
                        openHabitsCount: viewModel.openHabitsCount
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        Text(Constants.Text.tasksSectionTitle)
                            .font(.title2)
                            .bold()

                        if viewModel.tasks.isEmpty {
                            Text("Keine Aufgaben für heute.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        } else {
                            ForEach(viewModel.tasks) { task in
                                TaskCardView(task: task) {
                                    viewModel.toggleTask(task)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text(Constants.Text.habitsSectionTitle)
                            .font(.title2)
                            .bold()

                        if viewModel.habits.isEmpty {
                            Text("Noch keine Habits vorhanden.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        } else {
                            ForEach(viewModel.habits) { habit in
                                HabitCardView(habit: habit) {
                                    viewModel.toggleHabit(habit)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(Constants.Text.appName)
        }
    }
}

#Preview {
    HomeView()
}
