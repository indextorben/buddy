//
//  Item.swift
//  Buddy
//
//  Created by Torben Lehneke on 19.04.26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
