//
//  HomeViewModel.swift
//  Buddy
//
//  Created by Torben Lehneke on 19.04.26.
//

import Foundation
import Combine

final class HomeViewModel: ObservableObject {
    @Published var tasks: [Task]
    @Published var habits: [Habit]

    init(tasks: [Task] = DataService.sampleTasks,
         habits: [Habit] = DataService.sampleHabits) {
        self.tasks = tasks
        self.habits = habits
    }

    var openTasksCount: Int {
        tasks.filter { !$0.isDone }.count
    }

    var openHabitsCount: Int {
        habits.filter { !$0.isDone }.count
    }

    func toggleTask(_ task: Task) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isDone.toggle()
    }

    func toggleHabit(_ habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[index].isDone.toggle()
    }
}
