//
//  TasksView.swift
//  Buddy
//
//  Created by Torben Lehneke on 19.04.26.
//

import SwiftUI

struct TasksView: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(Constants.Text.tasksSectionTitle)
                    .font(.largeTitle)
                    .bold()

                if viewModel.tasks.isEmpty {
                    Text("Keine Aufgaben vorhanden.")
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

                Spacer(minLength: 0)
            }
            .padding()
        }
        .navigationTitle(Constants.Text.tasksSectionTitle)
    }
}

#Preview {
    NavigationView {
        TasksView(viewModel: HomeViewModel())
    }
}
