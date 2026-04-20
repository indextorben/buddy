//  StatsView.swift
import SwiftUI

struct StatsView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("accentColorHex") private var accentHex = "6C63FF"

    private let cal = Calendar.current

    // MARK: - Computed Stats

    private var last7Days: [Date] {
        (0..<7).compactMap { cal.date(byAdding: .day, value: -$0, to: cal.startOfDay(for: Date())) }
            .reversed()
    }

    private func completions(on date: Date) -> Int {
        viewModel.completionLog.filter { cal.isDate($0.date, inSameDayAs: date) }.count
    }

    private var currentStreak: Int {
        var streak = 0
        for day in last7Days.reversed() {
            if completions(on: day) > 0 { streak += 1 } else { break }
        }
        return streak
    }

    private var longestStreak: Int {
        let sorted = viewModel.completionLog.map { cal.startOfDay(for: $0.date) }
        let unique = Array(Set(sorted)).sorted()
        var best = 0, cur = 0
        for i in unique.indices {
            if i == 0 || cal.dateComponents([.day], from: unique[i-1], to: unique[i]).day == 1 {
                cur += 1; best = max(best, cur)
            } else { cur = 1 }
        }
        return best
    }

    private var weekTotal: Int {
        last7Days.reduce(0) { $0 + completions(on: $1) }
    }

    private var maxDay: Int {
        last7Days.map { completions(on: $0) }.max() ?? 1
    }

    // Habit frequency over last 30 days
    private var habitFrequency: [(title: String, count: Int)] {
        let cutoff = cal.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let habitEntries = viewModel.completionLog.filter { $0.type == .habit && $0.date >= cutoff }
        var counts: [String: Int] = [:]
        habitEntries.forEach { counts[$0.title, default: 0] += 1 }
        return counts.map { (title: $0.key, count: $0.value) }.sorted { $0.count > $1.count }
    }

    // Weekday productivity
    private var weekdayStats: [(name: String, count: Int)] {
        let names = ["So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"]
        var counts = [Int](repeating: 0, count: 7)
        viewModel.completionLog.forEach {
            let wd = cal.component(.weekday, from: $0.date) - 1
            counts[wd] += 1
        }
        return names.enumerated().map { (name: $0.element, count: counts[$0.offset]) }
    }

    private var todayRate: Double {
        let total = viewModel.tasks.count + viewModel.habits.count
        guard total > 0 else { return 0 }
        let done = viewModel.tasks.filter { $0.isDone }.count + viewModel.habits.filter { $0.isDone }.count
        return Double(done) / Double(total)
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {

                    // Heute
                    todayCard

                    // Streaks
                    streakCard

                    // 7-Tage-Verlauf
                    weekChart

                    // Wochentag-Analyse
                    weekdayCard

                    // Habit-Performance
                    if !habitFrequency.isEmpty { habitPerformanceCard }

                    Spacer().frame(height: 8)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Auswertungen")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .fontWeight(.semibold).foregroundColor(Color(hex: accentHex))
                }
            }
        }
    }

    // MARK: - Subviews

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            label("Heute", icon: "sun.max.fill", color: accentHex)
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Int(todayRate * 100)) %")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: accentHex))
                    Text("Erledigungsquote")
                        .font(.system(size: 12)).foregroundColor(.secondary)
                }
                Spacer()
                ZStack {
                    Circle().stroke(Color(hex: accentHex).opacity(0.15), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: todayRate)
                        .stroke(Color(hex: accentHex), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.8), value: todayRate)
                }
                .frame(width: 64, height: 64)
            }
        }
        .padding(16).background(card)
    }

    private var streakCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            label("Streaks", icon: "flame.fill", color: "FF6584")
            HStack(spacing: 0) {
                streakStat(value: currentStreak, title: "Aktuell", color: "FF6584")
                Divider().frame(height: 44)
                streakStat(value: longestStreak, title: "Rekord", color: "F97316")
                Divider().frame(height: 44)
                streakStat(value: weekTotal, title: "Diese Woche", color: accentHex)
            }
        }
        .padding(16).background(card)
    }

    private func streakStat(value: Int, title: String, color: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: color))
            Text(title)
                .font(.system(size: 11)).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var weekChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            label("7-Tage-Verlauf", icon: "chart.bar.fill", color: accentHex)
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(last7Days, id: \.self) { day in
                    let count = completions(on: day)
                    let h = maxDay > 0 ? CGFloat(count) / CGFloat(maxDay) : 0
                    VStack(spacing: 4) {
                        if count > 0 {
                            Text("\(count)").font(.system(size: 9, weight: .semibold))
                                .foregroundColor(Color(hex: accentHex))
                        }
                        RoundedRectangle(cornerRadius: 4)
                            .fill(count > 0 ? Color(hex: accentHex) : Color(hex: accentHex).opacity(0.12))
                            .frame(height: max(6, 60 * h))
                        Text(day.formatted(.dateTime.weekday(.abbreviated)))
                            .font(.system(size: 9, weight: .medium)).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 90)
        }
        .padding(16).background(card)
    }

    private var weekdayCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            label("Produktivste Tage", icon: "calendar.badge.clock", color: "10B981")
            let maxVal = weekdayStats.map(\.count).max() ?? 1
            ForEach(weekdayStats, id: \.name) { stat in
                HStack(spacing: 10) {
                    Text(stat.name)
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 24, alignment: .leading)
                        .foregroundColor(.secondary)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(hex: "10B981").opacity(0.1)).frame(height: 8)
                            Capsule().fill(Color(hex: "10B981"))
                                .frame(width: maxVal > 0 ? geo.size.width * CGFloat(stat.count) / CGFloat(maxVal) : 0,
                                       height: 8)
                        }
                    }
                    .frame(height: 8)
                    Text("\(stat.count)").font(.system(size: 11)).foregroundColor(.secondary)
                        .frame(width: 24, alignment: .trailing)
                }
            }
        }
        .padding(16).background(card)
    }

    private var habitPerformanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            label("Habits (letzte 30 Tage)", icon: "chart.line.uptrend.xyaxis", color: "8B5CF6")
            ForEach(habitFrequency.prefix(6), id: \.title) { item in
                HStack(spacing: 10) {
                    Circle().fill(Color(hex: "8B5CF6")).frame(width: 6, height: 6)
                    Text(item.title).font(.system(size: 13)).foregroundColor(.primary)
                    Spacer()
                    Text("\(item.count)×")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "8B5CF6"))
                }
            }
            if habitFrequency.last?.count == 0 || (habitFrequency.last.map { $0.count < 3 } == true) {
                let weak = habitFrequency.filter { $0.count < 3 }.map(\.title)
                if !weak.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11)).foregroundColor(Color(hex: "F97316"))
                        Text("Oft ausgelassen: \(weak.prefix(2).joined(separator: ", "))")
                            .font(.system(size: 11)).foregroundColor(Color(hex: "F97316"))
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(16).background(card)
    }

    private func label(_ t: String, icon: String, color: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 13, weight: .semibold)).foregroundColor(Color(hex: color))
            Text(t).font(.system(size: 13, weight: .bold)).foregroundColor(Color(hex: color))
        }
    }

    private var card: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color(.secondarySystemGroupedBackground))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}
