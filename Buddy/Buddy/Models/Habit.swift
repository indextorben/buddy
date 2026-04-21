//
//  Habit.swift
//  Buddy
//
//  Created by Torben Lehneke on 19.04.26.
//

import Foundation

struct Habit: Identifiable, Codable {
    var id = UUID()
    var title: String
    var isDone: Bool
}
