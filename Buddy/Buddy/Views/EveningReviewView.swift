//  EveningReviewView.swift
import SwiftUI

struct EveningReviewView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("accentColorHex") private var accentHex = "6C63FF"
    @AppStorage("buddyName")      private var buddyName = "Buddy"
    @AppStorage("tomorrowReminder") private var tomorrowReminder = ""

    @State private var reminderInput = ""
    @FocusState private var reminderFocused: Bool

    private var doneTasks:  [String] { viewModel.tasks.filter {  $0.isDone }.map { $0.title } }
    private var openTasks:  [String] { viewModel.tasks.filter { !$0.isDone }.map { $0.title } }
    private var doneHabits: [String] { viewModel.habits.filter {  $0.isDone }.map { $0.title } }
    private var openHabits: [String] { viewModel.habits.filter { !$0.isDone }.map { $0.title } }

    private var tomorrowFirst: String? {
        let rank = ["Hoch": 0, "Mittel": 1, "Niedrig": 2]
        return viewModel.tasks
            .filter { !$0.isDone }
            .sorted { (rank[$0.priority] ?? 1) < (rank[$1.priority] ?? 1) }
            .first?.title
    }

    private var scoreText: String {
        let total = viewModel.tasks.count + viewModel.habits.count
        let done  = doneTasks.count + doneHabits.count
        guard total > 0 else { return "Heute noch nichts geplant – morgen neu starten!" }
        let pct = Int(Double(done) / Double(total) * 100)
        switch pct {
        case 100:    return "100 % – perfekter Tag! Du hast alles erledigt. 🎉"
        case 75...:  return "\(pct) % geschafft – sehr guter Tag! Fast alles erledigt."
        case 50...:  return "\(pct) % geschafft – solider Tag. Morgen weiter!"
        default:     return "\(pct) % geschafft – nicht jeder Tag ist perfekt. Morgen frisch durchstarten!"
        }
    }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {

                    // Header
                    VStack(spacing: 6) {
                        Text("Guten Abend, \(buddyName)! 🌙")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                        Text(Date().formatted(date: .complete, time: .omitted))
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(LinearGradient(
                                colors: [Color(hex: "1E1B4B"), Color(hex: "4338CA")],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                    )

                    // Tagsbewertung
                    HStack(spacing: 10) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(hex: "F59E0B"))
                        Text(scoreText)
                            .font(.system(size: 14)).foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(card(Color(hex: "F59E0B")))

                    // Geschafft
                    if !doneTasks.isEmpty || !doneHabits.isEmpty {
                        reviewCard(
                            title: "Heute geschafft",
                            icon: "checkmark.seal.fill", color: "10B981",
                            items: doneTasks + doneHabits
                        )
                    }

                    // Offen geblieben
                    if !openTasks.isEmpty || !openHabits.isEmpty {
                        reviewCard(
                            title: "Offen geblieben",
                            icon: "clock.badge.exclamationmark", color: "F97316",
                            items: openTasks + openHabits
                        )
                    }

                    // Morgen zuerst
                    if let first = tomorrowFirst {
                        reviewCard(
                            title: "Morgen als erstes",
                            icon: "arrow.right.circle.fill", color: accentHex,
                            items: [first],
                            note: "Höchste Priorität – damit starten."
                        )
                    }

                    // Erinnerung für morgen
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(hex: "8B5CF6"))
                            Text("Erinnerung für morgen")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(hex: "8B5CF6"))
                        }
                        TextField("Was soll Buddy dich morgen erinnern?", text: $reminderInput, axis: .vertical)
                            .font(.system(size: 14)).focused($reminderFocused).lineLimit(2...4)
                        Button("Speichern") {
                            tomorrowReminder = reminderInput.trimmingCharacters(in: .whitespaces)
                            reminderFocused = false
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "8B5CF6"))
                        .disabled(reminderInput.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(card(Color(hex: "8B5CF6")))

                    Spacer().frame(height: 8)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Abend-Rückblick")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .fontWeight(.semibold).foregroundColor(Color(hex: accentHex))
                }
            }
            .onAppear { reminderInput = tomorrowReminder }
        }
    }

    private func card(_ accent: Color) -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(.secondarySystemGroupedBackground))
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    @ViewBuilder
    private func reviewCard(title: String, icon: String, color: String,
                             items: [String], note: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(Color(hex: color))
                Text(title)
                    .font(.system(size: 13, weight: .bold)).foregroundColor(Color(hex: color))
            }
            VStack(alignment: .leading, spacing: 6) {
                ForEach(items, id: \.self) { item in
                    HStack(spacing: 8) {
                        Circle().fill(Color(hex: color)).frame(width: 5, height: 5)
                        Text(item).font(.system(size: 14)).foregroundColor(.primary)
                    }
                }
            }
            if let note {
                Text(note).font(.system(size: 12)).foregroundColor(.secondary).padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(card(Color(hex: color)))
    }
}
