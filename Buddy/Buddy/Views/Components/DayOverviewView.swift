//
//  DayOverviewView.swift
//  Buddy
//
//  Created by Torben Lehneke on 19.04.26.
//

import SwiftUI

struct DayOverviewView: View {
    let openTasksCount: Int
    let openHabitsCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Constants.Text.greeting)
                .font(.largeTitle)
                .bold()

            Text(overviewText)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private var overviewText: String {
        if openTasksCount == 0 && openHabitsCount == 0 {
            return "Heute ist alles erledigt. Stark."
        } else if openTasksCount == 0 {
            return "Alle Aufgaben sind erledigt. Noch \(openHabitsCount) Habit\(openHabitsCount == 1 ? "" : "s") offen."
        } else if openHabitsCount == 0 {
            return "Noch \(openTasksCount) Aufgabe\(openTasksCount == 1 ? "" : "n") offen. Deine Habits sind schon geschafft."
        } else {
            return "Heute stehen \(openTasksCount) Aufgabe\(openTasksCount == 1 ? "" : "n") an und \(openHabitsCount) Habit\(openHabitsCount == 1 ? "" : "s") sind noch offen."
        }
    }
}

#Preview {
    DayOverviewView(openTasksCount: 3, openHabitsCount: 2)
        .padding()
}
