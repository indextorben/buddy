//
//  Task.swift
//  Buddy
//
//  Created by Torben Lehneke on 19.04.26.
//

import Foundation

struct Task: Identifiable, Codable {
    var id = UUID()
    var title: String
    var isDone: Bool
    var priority: String
}
