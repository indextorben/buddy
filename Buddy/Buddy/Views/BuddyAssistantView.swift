// BuddyAssistantView.swift
import SwiftUI

struct BuddyAssistantView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("buddyName") private var buddyName = "Buddy"
    @AppStorage("accentColorHex") private var accentHex = "6C63FF"
    @AppStorage("isPro") private var isPro = false

    @State private var splitTarget: Task? = nil
    @State private var splitInput = ""
    @State private var showSplitSheet = false
    @State private var deferredIDs: Set<UUID> = []

    private let cal = Calendar.current

    // MARK: - Analysis

    private var openTasks: [Task] { viewModel.tasks.filter { !$0.isDone } }
    private var openHabits: [Habit] { viewModel.habits.filter { !$0.isDone } }
    private var totalOpen: Int { openTasks.count + openHabits.count }

    private var isOverloaded: Bool { openTasks.count > 5 }

    private var priorityOrder: [Task] {
        let rank = ["Hoch": 0, "Mittel": 1, "Niedrig": 2]
        return openTasks.sorted { (rank[$0.priority] ?? 1) < (rank[$1.priority] ?? 1) }
    }

    private var deferCandidates: [Task] {
        let rank = ["Hoch": 0, "Mittel": 1, "Niedrig": 2]
        return openTasks
            .filter { !deferredIDs.contains($0.id) }
            .sorted { (rank[$0.priority] ?? 1) > (rank[$1.priority] ?? 1) }
            .prefix(3)
            .map { $0 }
    }

    private var dailyGoal: String {
        guard !openTasks.isEmpty else { return "Heute keine offenen Aufgaben – entspann dich!" }
        let focus = priorityOrder.first.map { $0.title } ?? ""
        let habitCount = openHabits.count
        if isOverloaded {
            return "Fokus auf '\(focus)' + \(habitCount) Habit\(habitCount == 1 ? "" : "s"). Rest morgen."
        }
        if habitCount > 0 {
            return "'\(focus)' erledigen & \(habitCount) Habit\(habitCount == 1 ? "" : "s") nicht vergessen."
        }
        return "'\(focus)' steht heute an erster Stelle."
    }

    private var mood: (icon: String, color: String, label: String) {
        switch totalOpen {
        case 0:       return ("checkmark.seal.fill", "10B981", "Alles erledigt!")
        case 1...3:   return ("face.smiling.fill", "6C63FF", "Gut machbar")
        case 4...5:   return ("exclamationmark.circle.fill", "F59E0B", "Viel auf dem Teller")
        default:      return ("flame.fill", "EF4444", "Überladen!")
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if !isPro { proGateBanner }
                    statusCard
                    goalCard
                    if isOverloaded { overloadCard }
                    priorityCard
                    splitCard
                    Spacer().frame(height: 8)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("\(buddyName) Assistant")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .fontWeight(.semibold).foregroundColor(Color(hex: accentHex))
                }
            }
        }
        .sheet(isPresented: $showSplitSheet) { splitSheet }
    }

    // MARK: - Cards

    private var proGateBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill").foregroundColor(Color(hex: "F59E0B"))
            Text("Pro-Feature – Alle Vorschläge freischalten")
                .font(.system(size: 13, weight: .semibold)).foregroundColor(Color(hex: "F59E0B"))
            Spacer()
            Button("Upgrade") { isPro = true }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Color(hex: "F59E0B"))
                .clipShape(Capsule())
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color(hex: "F59E0B").opacity(0.1)))
    }

    private var statusCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(Color(hex: mood.color).opacity(0.15)).frame(width: 52, height: 52)
                Image(systemName: mood.icon)
                    .font(.system(size: 22)).foregroundColor(Color(hex: mood.color))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(mood.label)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: mood.color))
                Text("\(totalOpen) Einträge offen · \(openTasks.count) Aufgaben · \(openHabits.count) Habits")
                    .font(.system(size: 12)).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(16).background(card)
    }

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Tagesziel", icon: "scope", color: accentHex)
            Text(dailyGoal)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16).background(card)
    }

    private var overloadCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Heute zu voll", icon: "exclamationmark.triangle.fill", color: "EF4444")
            Text("Du hast \(openTasks.count) offene Aufgaben. Verschiebe einige auf morgen:")
                .font(.system(size: 13)).foregroundColor(.secondary)
            ForEach(deferCandidates) { task in
                HStack(spacing: 10) {
                    priorityDot(task.priority)
                    Text(task.title).font(.system(size: 14)).foregroundColor(.primary)
                    Spacer()
                    Button {
                        withAnimation { _ = deferredIDs.insert(task.id) }
                    } label: {
                        Text("Verschieben")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "EF4444"))
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Color(hex: "EF4444").opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            if !deferredIDs.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(Color(hex: "10B981"))
                    Text("\(deferredIDs.count) auf morgen notiert")
                        .font(.system(size: 12)).foregroundColor(Color(hex: "10B981"))
                }
                .padding(.top, 4)
            }
        }
        .padding(16).background(card)
    }

    private var priorityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Vorgeschlagene Reihenfolge", icon: "arrow.up.arrow.down", color: "6C63FF")
            if priorityOrder.isEmpty {
                Text("Keine offenen Aufgaben").font(.system(size: 13)).foregroundColor(.secondary)
            } else {
                ForEach(Array(priorityOrder.prefix(5).enumerated()), id: \.element.id) { idx, task in
                    HStack(spacing: 10) {
                        Text("\(idx + 1)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(Color(hex: accentHex)))
                        priorityDot(task.priority)
                        Text(task.title).font(.system(size: 14)).foregroundColor(.primary)
                        Spacer()
                        Text(task.priority)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(priorityColor(task.priority))
                    }
                }
            }
        }
        .padding(16).background(card)
    }

    private var splitCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Aufgabe aufteilen", icon: "scissors", color: "8B5CF6")
            Text("Wähle eine große Aufgabe, damit Buddy sie in kleinere Schritte zerlegt.")
                .font(.system(size: 12)).foregroundColor(.secondary)
            if openTasks.isEmpty {
                Text("Keine Aufgaben vorhanden").font(.system(size: 13)).foregroundColor(.secondary)
            } else {
                ForEach(openTasks.prefix(4)) { task in
                    Button {
                        splitTarget = task
                        splitInput = ""
                        showSplitSheet = true
                    } label: {
                        HStack(spacing: 10) {
                            priorityDot(task.priority)
                            Text(task.title).font(.system(size: 14)).foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "scissors")
                                .font(.system(size: 12)).foregroundColor(Color(hex: "8B5CF6"))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16).background(card)
    }

    // MARK: - Split Sheet

    private var splitSheet: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                if let t = splitTarget {
                    Text("Aufgabe: \(t.title)")
                        .font(.system(size: 15, weight: .semibold)).foregroundColor(.primary)
                        .padding(.horizontal, 16)
                    Text("Trage Teilschritte ein (einer pro Zeile):")
                        .font(.system(size: 13)).foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                    TextEditor(text: $splitInput)
                        .font(.system(size: 14))
                        .frame(minHeight: 140)
                        .padding(8)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal, 16)
                    let steps = splitInput
                        .components(separatedBy: "\n")
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                    if !steps.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Vorschau (\(steps.count) Teilschritte):")
                                .font(.system(size: 12, weight: .semibold)).foregroundColor(.secondary)
                            ForEach(steps, id: \.self) { step in
                                HStack(spacing: 8) {
                                    Circle().fill(Color(hex: "8B5CF6")).frame(width: 5, height: 5)
                                    Text(step).font(.system(size: 13)).foregroundColor(.primary)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        Button {
                            let steps = splitInput
                                .components(separatedBy: "\n")
                                .map { $0.trimmingCharacters(in: .whitespaces) }
                                .filter { !$0.isEmpty }
                            for step in steps {
                                viewModel.tasks.append(Task(title: step, isDone: false, priority: t.priority))
                            }
                            if let idx = viewModel.tasks.firstIndex(where: { $0.id == t.id }) {
                                viewModel.tasks.remove(at: idx)
                            }
                            showSplitSheet = false
                        } label: {
                            Text("Aufteilen & Original ersetzen")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(hex: "8B5CF6"))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .padding(.horizontal, 16)
                    }
                    Spacer()
                }
            }
            .padding(.top, 16)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Aufgabe aufteilen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Abbrechen") { showSplitSheet = false }
                }
            }
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ t: String, icon: String, color: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 13, weight: .semibold)).foregroundColor(Color(hex: color))
            Text(t).font(.system(size: 13, weight: .bold)).foregroundColor(Color(hex: color))
        }
    }

    private func priorityDot(_ p: String) -> some View {
        Circle().fill(Color(hex: priorityColorHex(p))).frame(width: 7, height: 7)
    }

    private func priorityColorHex(_ p: String) -> String {
        switch p {
        case "Hoch":    return "EF4444"
        case "Mittel":  return "F59E0B"
        default:        return "10B981"
        }
    }

    private func priorityColor(_ p: String) -> Color {
        Color(hex: priorityColorHex(p))
    }

    private var card: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color(.secondarySystemGroupedBackground))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}
