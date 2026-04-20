//  MorningBriefingView.swift
import SwiftUI

struct MorningBriefingView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("accentColorHex") private var accentHex = "6C63FF"
    @AppStorage("buddyName")      private var buddyName = "Buddy"

    private var focusTask: String? {
        let pending = viewModel.tasks.filter { !$0.isDone }
        let sorted  = pending.sorted { priorityRank($0.priority) < priorityRank($1.priority) }
        return sorted.first?.title
    }
    private var urgentTasks: [String] {
        viewModel.tasks.filter { !$0.isDone && $0.priority == "Hoch" }.map { $0.title }
    }
    private var otherTasks: [String] {
        viewModel.tasks.filter { !$0.isDone && $0.priority != "Hoch" }.map { $0.title }
    }
    private var openHabits: [String] {
        viewModel.habits.filter { !$0.isDone }.map { $0.title }
    }
    private var todayAppts: [String] {
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        fmt.dateStyle = .none
        return viewModel.todayAppointments.map { "\(fmt.string(from: $0.time)) – \($0.title)" }
    }

    private var summary: String {
        let total   = viewModel.tasks.count + viewModel.habits.count
        let openCnt = viewModel.tasks.filter { !$0.isDone }.count
                    + viewModel.habits.filter { !$0.isDone }.count
        guard total > 0 else {
            return "Du hast heute noch nichts geplant. Füge Aufgaben hinzu und leg los!"
        }
        guard openCnt > 0 else {
            return "Alle \(total) Einträge sind erledigt. Perfekter Start! 🎉"
        }
        let pct     = Int(Double(total - openCnt) / Double(total) * 100)
        let urgent  = urgentTasks.count
        if urgent == 0 {
            return "Du hast \(openCnt) offene Einträge. Fang mit den mittleren Prioritäten an – du schaffst das!"
        }
        let suffix  = urgent == 1 ? "" : "n"
        return "\(urgent) dringende Aufgabe\(suffix) warten auf dich. Erledige sie zuerst. Aktuell \(pct) % des Tages geschafft."
    }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {

                    // Header
                    VStack(spacing: 6) {
                        Text("Guten Morgen, \(buddyName)! ☀️")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                        Text(Date().formatted(date: .complete, time: .omitted))
                            .font(.system(size: 13)).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(LinearGradient(
                                colors: [Color(hex: "6C63FF"), Color(hex: "A78BFA")],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
                    .foregroundColor(.white)

                    // Fokus-Empfehlung
                    if let f = focusTask {
                        briefingCard(
                            title: "Fokus-Empfehlung",
                            icon: "scope", color: "6C63FF",
                            items: [f],
                            note: "Starte deinen Tag mit dieser Aufgabe."
                        )
                    }

                    // Dringend
                    if !urgentTasks.isEmpty {
                        briefingCard(
                            title: "Dringend",
                            icon: "exclamationmark.circle.fill", color: "EF4444",
                            items: urgentTasks
                        )
                    }

                    // Weitere Aufgaben
                    if !otherTasks.isEmpty {
                        briefingCard(
                            title: "Aufgaben heute",
                            icon: "checkmark.circle", color: accentHex,
                            items: otherTasks
                        )
                    }

                    // Habits
                    if !openHabits.isEmpty {
                        briefingCard(
                            title: "Habits für heute",
                            icon: "flame.fill", color: "FF6584",
                            items: openHabits
                        )
                    }

                    // Termine
                    if !todayAppts.isEmpty {
                        briefingCard(
                            title: "Termine",
                            icon: "calendar", color: "3B82F6",
                            items: todayAppts
                        )
                    }

                    // Zusammenfassung
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(hex: "F59E0B"))
                        Text(summary)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(hex: "F59E0B").opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color(hex: "F59E0B").opacity(0.2), lineWidth: 1)
                            )
                    )

                    Spacer().frame(height: 8)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Morgen-Briefing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .fontWeight(.semibold).foregroundColor(Color(hex: accentHex))
                }
            }
        }
    }

    @ViewBuilder
    private func briefingCard(title: String, icon: String, color: String,
                               items: [String], note: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: color))
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: color))
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
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }

    private func priorityRank(_ p: String) -> Int {
        ["Hoch": 0, "Mittel": 1, "Niedrig": 2][p] ?? 1
    }
}
