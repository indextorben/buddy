//
//  HabitsView.swift
//  Buddy
//
//  Created by Torben Lehneke on 19.04.26.
//

import SwiftUI

struct HabitsView: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(Constants.Text.habitsSectionTitle)
                    .font(.largeTitle)
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

                Spacer(minLength: 0)
            }
            .padding()
        }
        .navigationTitle(Constants.Text.habitsSectionTitle)
    }
}

#Preview {
    NavigationView {
        HabitsView(viewModel: HomeViewModel())
    }
}
