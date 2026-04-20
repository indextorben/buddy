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
    @Published var appointments: [Appointment] = []
    @Published var notes: [Note] = []
    @Published var shoppingItems: [ShoppingItem] = []
    @Published var deadlines: [Deadline] = []
    @Published var delegatedItems: [DelegatedItem] = []
    @Published var recurringTasks: [RecurringTask] = []
    @Published var birthdays: [Birthday] = []
    @Published var ideas: [Idea] = []
    @Published var projects: [Project] = []

    @Published var completionLog: [CompletionEntry] = [] {
        didSet {
            if let data = try? JSONEncoder().encode(completionLog) {
                UserDefaults.standard.set(data, forKey: "buddy_completionLog")
            }
        }
    }

    init(tasks: [Task] = DataService.sampleTasks,
         habits: [Habit] = DataService.sampleHabits) {
        self.tasks = tasks
        self.habits = habits
        if let data = UserDefaults.standard.data(forKey: "buddy_completionLog"),
           let log = try? JSONDecoder().decode([CompletionEntry].self, from: data) {
            completionLog = log
        }
    }

    // MARK: - Day Plan

    func generateDayPlan() -> [DayPlanItem] {
        let cal = Calendar.current
        let now = Date()

        func startOfWorkday() -> Date {
            cal.date(bySettingHour: 8, minute: 0, second: 0, of: now) ?? now
        }
        func roundUp(_ date: Date) -> Date {
            let m = cal.component(.minute, from: date)
            let add = m == 0 ? 0 : (m <= 30 ? 30 - m : 60 - m)
            return cal.date(byAdding: .minute, value: add, to: date) ?? date
        }

        var cursor = roundUp(now > startOfWorkday() ? now : startOfWorkday())
        var plan: [DayPlanItem] = []

        let priorityRank = ["Hoch": 0, "Mittel": 1, "Niedrig": 2]
        var taskQ = tasks.filter { !$0.isDone }
            .sorted { (priorityRank[$0.priority] ?? 1) < (priorityRank[$1.priority] ?? 1) }
        var habitQ   = habits.filter { !$0.isDone }
        var apptQ    = todayAppointments                  // already sorted

        func place(_ item: DayPlanItem) {
            plan.append(item)
            cursor = item.endTime.addingTimeInterval(15 * 60) // 15 min Puffer
        }
        func fitTask() {
            guard !taskQ.isEmpty else { return }
            let t = taskQ.removeFirst()
            place(DayPlanItem(startTime: cursor, duration: 45,
                              title: t.title, type: .task, priority: t.priority))
        }
        func fitHabit() {
            guard !habitQ.isEmpty else { return }
            let h = habitQ.removeFirst()
            place(DayPlanItem(startTime: cursor, duration: 20, title: h.title, type: .habit))
        }

        // Morgen-Habit zuerst (vor 9 Uhr)
        let nineAM = cal.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now
        if cursor < nineAM { fitHabit() }

        // Termine füllen + Lücken mit Tasks
        for appt in apptQ {
            let gap = appt.time.timeIntervalSince(cursor)
            if gap >= 60 * 60 { fitTask() }
            else if gap >= 20 * 60 { fitHabit() }
            // Termin platzieren
            plan.append(DayPlanItem(startTime: appt.time, duration: 60,
                                    title: appt.title, type: .appointment))
            cursor = appt.time.addingTimeInterval(75 * 60)  // 60 + 15 Puffer
        }

        // Restliche Tasks
        while !taskQ.isEmpty {
            fitTask()
            if !taskQ.isEmpty {
                plan.append(DayPlanItem(startTime: cursor.addingTimeInterval(-15*60),
                                        duration: 15, title: "Kurze Pause", type: .pause))
            }
        }

        // Abend-Habits ab 19 Uhr
        let sevenPM = cal.date(bySettingHour: 19, minute: 0, second: 0, of: now) ?? cursor
        cursor = max(cursor, sevenPM)
        while !habitQ.isEmpty { fitHabit() }

        return plan.sorted { $0.startTime < $1.startTime }
    }

    var todayAppointments: [Appointment] {
        appointments
            .filter { Calendar.current.isDateInToday($0.time) }
            .sorted { $0.time < $1.time }
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
        if tasks[index].isDone {
            completionLog.append(CompletionEntry(id: UUID(), date: Date(), title: task.title, type: .task))
        }
    }

    func toggleHabit(_ habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[index].isDone.toggle()
        if habits[index].isDone {
            completionLog.append(CompletionEntry(id: UUID(), date: Date(), title: habit.title, type: .habit))
        }
    }
}
