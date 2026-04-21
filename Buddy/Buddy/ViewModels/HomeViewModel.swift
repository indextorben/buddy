//
//  HomeViewModel.swift
//  Buddy
//
//  Created by Torben Lehneke on 19.04.26.
//

import Foundation
import Combine

final class HomeViewModel: ObservableObject {

    // MARK: - Published Data

    @Published var tasks:          [Task]           = [] { didSet { persist("buddy_tasks",        tasks) } }
    @Published var habits:         [Habit]          = [] { didSet { persist("buddy_habits",       habits) } }
    @Published var appointments:   [Appointment]    = [] { didSet { persist("buddy_appointments", appointments) } }
    @Published var notes:          [Note]           = [] { didSet { persist("buddy_notes",        notes) } }
    @Published var shoppingItems:  [ShoppingItem]   = [] { didSet { persist("buddy_shopping",     shoppingItems) } }
    @Published var deadlines:      [Deadline]       = [] { didSet { persist("buddy_deadlines",    deadlines) } }
    @Published var delegatedItems: [DelegatedItem]  = [] { didSet { persist("buddy_delegated",    delegatedItems) } }
    @Published var recurringTasks: [RecurringTask]  = [] { didSet { persist("buddy_recurring",    recurringTasks) } }
    @Published var birthdays:      [Birthday]       = [] { didSet { persist("buddy_birthdays",    birthdays) } }
    @Published var ideas:          [Idea]           = [] { didSet { persist("buddy_ideas",        ideas) } }
    @Published var projects:       [Project]        = [] { didSet { persist("buddy_projects",     projects) } }
    @Published var completionLog:  [CompletionEntry] = [] { didSet { persist("buddy_completionLog", completionLog) } }

    // MARK: - Init

    init() {
        tasks          = stored("buddy_tasks")          ?? DataService.sampleTasks
        habits         = stored("buddy_habits")         ?? DataService.sampleHabits
        appointments   = stored("buddy_appointments")   ?? []
        notes          = stored("buddy_notes")          ?? []
        shoppingItems  = stored("buddy_shopping")       ?? []
        deadlines      = stored("buddy_deadlines")      ?? []
        delegatedItems = stored("buddy_delegated")      ?? []
        recurringTasks = stored("buddy_recurring")      ?? []
        birthdays      = stored("buddy_birthdays")      ?? []
        ideas          = stored("buddy_ideas")          ?? []
        projects       = stored("buddy_projects")       ?? []
        completionLog  = stored("buddy_completionLog")  ?? []

        observeICloud()
    }

    // MARK: - iCloud Sync

    var iCloudSyncEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "iCloudSyncEnabled") }
        set {
            UserDefaults.standard.set(newValue, forKey: "iCloudSyncEnabled")
            if newValue { pushToICloud() }
        }
    }

    private func observeICloud() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(iCloudDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default
        )
        NSUbiquitousKeyValueStore.default.synchronize()
    }

    @objc private func iCloudDidChange(_ note: Notification) {
        guard iCloudSyncEnabled else { return }
        DispatchQueue.main.async { self.pullFromICloud() }
    }

    private func pushToICloud() {
        let store = NSUbiquitousKeyValueStore.default
        let ud = UserDefaults.standard
        let keys = [
            "buddy_tasks", "buddy_habits", "buddy_appointments", "buddy_notes",
            "buddy_shopping", "buddy_deadlines", "buddy_delegated", "buddy_recurring",
            "buddy_birthdays", "buddy_ideas", "buddy_projects", "buddy_completionLog"
        ]
        for key in keys {
            if let data = ud.data(forKey: key) {
                store.set(data, forKey: key)
            }
        }
        store.synchronize()
    }

    private func pullFromICloud() {
        let store = NSUbiquitousKeyValueStore.default
        func pull<T: Codable>(_ key: String) -> [T]? {
            guard let data = store.data(forKey: key) else { return nil }
            return try? JSONDecoder().decode([T].self, from: data)
        }
        if let v: [Task]          = pull("buddy_tasks")        { tasks          = v }
        if let v: [Habit]         = pull("buddy_habits")       { habits         = v }
        if let v: [Appointment]   = pull("buddy_appointments") { appointments   = v }
        if let v: [Note]          = pull("buddy_notes")        { notes          = v }
        if let v: [ShoppingItem]  = pull("buddy_shopping")     { shoppingItems  = v }
        if let v: [Deadline]      = pull("buddy_deadlines")    { deadlines      = v }
        if let v: [DelegatedItem] = pull("buddy_delegated")    { delegatedItems = v }
        if let v: [RecurringTask] = pull("buddy_recurring")    { recurringTasks = v }
        if let v: [Birthday]      = pull("buddy_birthdays")    { birthdays      = v }
        if let v: [Idea]          = pull("buddy_ideas")        { ideas          = v }
        if let v: [Project]       = pull("buddy_projects")     { projects       = v }
        if let v: [CompletionEntry] = pull("buddy_completionLog") { completionLog = v }
    }

    // MARK: - Storage Helpers

    private func persist<T: Codable>(_ key: String, _ value: T) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
        if iCloudSyncEnabled {
            NSUbiquitousKeyValueStore.default.set(data, forKey: key)
            NSUbiquitousKeyValueStore.default.synchronize()
        }
    }

    private func stored<T: Codable>(_ key: String) -> T? {
        // Prefer iCloud data when sync is enabled and iCloud has newer/existing data
        if iCloudSyncEnabled,
           let data = NSUbiquitousKeyValueStore.default.data(forKey: key),
           let value = try? JSONDecoder().decode(T.self, from: data) {
            return value
        }
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
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
        var apptQ    = todayAppointments

        func place(_ item: DayPlanItem) {
            plan.append(item)
            cursor = item.endTime.addingTimeInterval(15 * 60)
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

        let nineAM = cal.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now
        if cursor < nineAM { fitHabit() }

        for appt in apptQ {
            let gap = appt.time.timeIntervalSince(cursor)
            if gap >= 60 * 60 { fitTask() }
            else if gap >= 20 * 60 { fitHabit() }
            plan.append(DayPlanItem(startTime: appt.time, duration: 60,
                                    title: appt.title, type: .appointment))
            cursor = appt.time.addingTimeInterval(75 * 60)
        }

        while !taskQ.isEmpty {
            fitTask()
            if !taskQ.isEmpty {
                plan.append(DayPlanItem(startTime: cursor.addingTimeInterval(-15*60),
                                        duration: 15, title: "Kurze Pause", type: .pause))
            }
        }

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

    var openTasksCount: Int  { tasks.filter  { !$0.isDone }.count }
    var openHabitsCount: Int { habits.filter { !$0.isDone }.count }

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
