//
//  Untitled.swift
//  Buddy
//
//  Created by Torben Lehneke on 19.04.26.
//

import Foundation

final class DataService {
    static let sampleTasks: [Task] = [
        Task(title: "Mathe lernen", isDone: false, priority: "Hoch"),
        Task(title: "E-Mails beantworten", isDone: false, priority: "Mittel"),
        Task(title: "Zimmer aufräumen", isDone: true, priority: "Niedrig")
    ]

    static let sampleHabits: [Habit] = [
        Habit(title: "2L Wasser trinken", isDone: false),
        Habit(title: "10 Minuten lesen", isDone: true),
        Habit(title: "Spaziergang", isDone: false)
    ]
}
