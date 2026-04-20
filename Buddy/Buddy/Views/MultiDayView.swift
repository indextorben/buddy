//  MultiDayView.swift
import SwiftUI

// MARK: - Container

struct MultiDayView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("accentColorHex") private var accentHex = "6C63FF"
    @AppStorage("isPro") private var isPro = false
    @State private var mode: DayMode = .today
    @State private var showProGate = false

    enum DayMode: String, CaseIterable {
        case today   = "Heute"
        case tomorrow = "Morgen"
        case week    = "Woche"
        case month   = "Monat"
        case focus   = "Fokus"
        case agenda  = "Agenda"

        var icon: String {
            switch self {
            case .today:    return "sun.max.fill"
            case .tomorrow: return "sunrise.fill"
            case .week:     return "calendar.badge.clock"
            case .month:    return "calendar"
            case .focus:    return "scope"
            case .agenda:   return "list.bullet.rectangle"
            }
        }
        var isPro: Bool { self != .today }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                modePicker
                Divider()
                Group {
                    switch mode {
                    case .today:    TodayMiniView(viewModel: viewModel)
                    case .tomorrow: TomorrowView(viewModel: viewModel)
                    case .week:     WeekView(viewModel: viewModel)
                    case .month:    MonthView(viewModel: viewModel)
                    case .focus:    FocusModeView(viewModel: viewModel)
                    case .agenda:   AgendaView(viewModel: viewModel)
                    }
                }
            }
            .navigationTitle(mode.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !isPro {
                        Button {
                            showProGate = true
                        } label: {
                            Label("Pro", systemImage: "crown.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(hex: "F59E0B"))
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .fontWeight(.semibold).foregroundColor(Color(hex: accentHex))
                }
            }
            .sheet(isPresented: $showProGate) { ProGateView(isPro: $isPro) }
        }
    }

    private var modePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(DayMode.allCases, id: \.self) { m in
                    let locked = m.isPro && !isPro
                    Button {
                        if locked { showProGate = true } else { withAnimation { mode = m } }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: locked ? "lock.fill" : m.icon)
                                .font(.system(size: 11, weight: .semibold))
                            Text(m.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(mode == m ? .white : locked ? Color(.tertiaryLabel) : Color(hex: accentHex))
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(
                            Capsule().fill(mode == m ? Color(hex: accentHex) : Color(hex: accentHex).opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
        }
    }
}

// MARK: - Heute (Mini)

private struct TodayMiniView: View {
    @ObservedObject var viewModel: HomeViewModel
    @AppStorage("accentColorHex") private var accentHex = "6C63FF"
    var body: some View {
        List {
            if !viewModel.tasks.isEmpty {
                Section("Aufgaben") {
                    ForEach(viewModel.tasks) { t in
                        HStack {
                            Image(systemName: t.isDone ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(t.isDone ? Color(hex: accentHex) : Color(.tertiaryLabel))
                            Text(t.title).foregroundColor(t.isDone ? .secondary : .primary)
                                .strikethrough(t.isDone)
                        }
                    }
                }
            }
            if !viewModel.habits.isEmpty {
                Section("Habits") {
                    ForEach(viewModel.habits) { h in
                        HStack {
                            Image(systemName: h.isDone ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(h.isDone ? Color(hex: "FF6584") : Color(.tertiaryLabel))
                            Text(h.title).foregroundColor(h.isDone ? .secondary : .primary)
                                .strikethrough(h.isDone)
                        }
                    }
                }
            }
        }.listStyle(.insetGrouped)
    }
}

// MARK: - Morgen

private struct TomorrowView: View {
    @ObservedObject var viewModel: HomeViewModel
    @AppStorage("accentColorHex") private var accentHex = "6C63FF"
    private var tomorrowAppts: [Appointment] {
        let cal  = Calendar.current
        let tom  = cal.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return viewModel.appointments.filter { cal.isDate($0.time, inSameDayAs: tom) }
            .sorted { $0.time < $1.time }
    }
    private var recommended: [String] {
        let rank = ["Hoch": 0, "Mittel": 1, "Niedrig": 2]
        return viewModel.tasks.filter { !$0.isDone }
            .sorted { (rank[$0.priority] ?? 1) < (rank[$1.priority] ?? 1) }
            .prefix(5).map { $0.title }
    }
    var body: some View {
        List {
            if !tomorrowAppts.isEmpty {
                Section("Termine morgen") {
                    ForEach(tomorrowAppts) { a in
                        HStack {
                            Image(systemName: "calendar").foregroundColor(Color(hex: "3B82F6"))
                            VStack(alignment: .leading) {
                                Text(a.title)
                                Text(a.time.formatted(.dateTime.hour().minute()))
                                    .font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            Section("Empfohlen für morgen") {
                if recommended.isEmpty {
                    Text("Keine offenen Aufgaben").foregroundColor(.secondary)
                } else {
                    ForEach(recommended, id: \.self) { t in
                        Label(t, systemImage: "arrow.right.circle").foregroundColor(Color(hex: accentHex))
                    }
                }
            }
        }.listStyle(.insetGrouped)
    }
}

// MARK: - Woche

private struct WeekView: View {
    @ObservedObject var viewModel: HomeViewModel
    @AppStorage("accentColorHex") private var accentHex = "6C63FF"
    private let cal = Calendar.current
    private var days: [Date] {
        (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: cal.startOfDay(for: Date())) }
    }
    private func appts(on date: Date) -> [Appointment] {
        viewModel.appointments.filter { cal.isDate($0.time, inSameDayAs: date) }
    }
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(days, id: \.self) { day in
                    let apptList = appts(on: day)
                    let isToday  = cal.isDateInToday(day)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(day.formatted(.dateTime.weekday(.wide).day().month()))
                                .font(.system(size: 13, weight: isToday ? .bold : .medium))
                                .foregroundColor(isToday ? Color(hex: accentHex) : .primary)
                            Spacer()
                            if isToday {
                                Text("Heute").font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white).padding(.horizontal, 8).padding(.vertical, 2)
                                    .background(Capsule().fill(Color(hex: accentHex)))
                            }
                        }
                        if apptList.isEmpty {
                            Text("Keine Termine").font(.system(size: 12)).foregroundColor(Color(.tertiaryLabel))
                        } else {
                            ForEach(apptList) { a in
                                HStack(spacing: 6) {
                                    Circle().fill(Color(hex: "3B82F6")).frame(width: 5, height: 5)
                                    Text("\(a.time.formatted(.dateTime.hour().minute())) – \(a.title)")
                                        .font(.system(size: 12)).foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12)
                        .fill(isToday ? Color(hex: accentHex).opacity(0.06) : Color(.secondarySystemGroupedBackground)))
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

// MARK: - Monat

private struct MonthView: View {
    @ObservedObject var viewModel: HomeViewModel
    @AppStorage("accentColorHex") private var accentHex = "6C63FF"
    @State private var displayMonth = Date()
    private let cal = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdays = ["Mo","Di","Mi","Do","Fr","Sa","So"]

    private var daysInMonth: [Date?] {
        guard let range = cal.range(of: .day, in: .month, for: displayMonth),
              let first = cal.date(from: cal.dateComponents([.year,.month], from: displayMonth)) else { return [] }
        let weekday = (cal.component(.weekday, from: first) + 5) % 7
        var days: [Date?] = Array(repeating: nil, count: weekday)
        days += range.compactMap { cal.date(byAdding: .day, value: $0 - 1, to: first) }
        return days
    }

    private func hasAppt(_ date: Date) -> Bool {
        viewModel.appointments.contains { cal.isDate($0.time, inSameDayAs: date) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Month nav
            HStack {
                Button { displayMonth = cal.date(byAdding: .month, value: -1, to: displayMonth) ?? displayMonth } label: {
                    Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold))
                }
                Spacer()
                Text(displayMonth.formatted(.dateTime.year().month(.wide)))
                    .font(.system(size: 17, weight: .bold))
                Spacer()
                Button { displayMonth = cal.date(byAdding: .month, value: 1, to: displayMonth) ?? displayMonth } label: {
                    Image(systemName: "chevron.right").font(.system(size: 16, weight: .semibold))
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 12)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(weekdays, id: \.self) { d in
                    Text(d).font(.system(size: 11, weight: .semibold)).foregroundColor(.secondary)
                }
                ForEach(daysInMonth.indices, id: \.self) { i in
                    if let date = daysInMonth[i] {
                        let isToday = cal.isDateInToday(date)
                        let dot     = hasAppt(date)
                        VStack(spacing: 3) {
                            Text("\(cal.component(.day, from: date))")
                                .font(.system(size: 14, weight: isToday ? .bold : .regular))
                                .foregroundColor(isToday ? .white : .primary)
                                .frame(width: 30, height: 30)
                                .background(isToday ? Circle().fill(Color(hex: accentHex)) : nil)
                            Circle().fill(dot ? Color(hex: "3B82F6") : Color.clear).frame(width: 4, height: 4)
                        }
                    } else {
                        Color.clear.frame(height: 38)
                    }
                }
            }
            .padding(.horizontal, 12)
            Spacer()
        }
    }
}

// MARK: - Fokus

private struct FocusModeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @AppStorage("accentColorHex") private var accentHex = "6C63FF"
    private var topTask: (index: Int, task: Task)? {
        let rank = ["Hoch": 0, "Mittel": 1, "Niedrig": 2]
        guard let idx = viewModel.tasks
            .filter({ !$0.isDone })
            .sorted(by: { (rank[$0.priority] ?? 1) < (rank[$1.priority] ?? 1) })
            .first
            .flatMap({ t in viewModel.tasks.firstIndex(where: { $0.id == t.id }) })
        else { return nil }
        return (idx, viewModel.tasks[idx])
    }
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            if let item = topTask {
                VStack(spacing: 20) {
                    Image(systemName: "scope")
                        .font(.system(size: 52)).foregroundColor(Color(hex: accentHex).opacity(0.6))
                    Text("Jetzt fokussieren auf:")
                        .font(.system(size: 14)).foregroundColor(.secondary)
                    Text(item.task.title)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center).padding(.horizontal, 32)
                    let colors = ["Hoch": "EF4444", "Mittel": "F97316", "Niedrig": "10B981"]
                    Text(item.task.priority)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: colors[item.task.priority] ?? "9CA3AF"))
                        .padding(.horizontal, 12).padding(.vertical, 5)
                        .background(Capsule().fill(Color(hex: colors[item.task.priority] ?? "9CA3AF").opacity(0.12)))
                    Button {
                        withAnimation { viewModel.tasks[item.index].isDone = true }
                    } label: {
                        Label("Erledigt!", systemImage: "checkmark")
                            .font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: accentHex)))
                    }
                    .padding(.horizontal, 32)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 52)).foregroundColor(Color(hex: accentHex).opacity(0.4))
                    Text("Alles erledigt!").font(.system(size: 20, weight: .bold))
                }
            }
            Spacer()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

// MARK: - Agenda

private struct AgendaView: View {
    @ObservedObject var viewModel: HomeViewModel
    @AppStorage("accentColorHex") private var accentHex = "6C63FF"
    private let cal = Calendar.current
    private var days: [Date] {
        (0..<14).compactMap { cal.date(byAdding: .day, value: $0, to: cal.startOfDay(for: Date())) }
    }
    private func appts(on date: Date) -> [Appointment] {
        viewModel.appointments.filter { cal.isDate($0.time, inSameDayAs: date) }.sorted { $0.time < $1.time }
    }
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(days.filter { !appts(on: $0).isEmpty }, id: \.self) { day in
                    VStack(alignment: .leading, spacing: 0) {
                        Text(day.formatted(.dateTime.weekday(.wide).day().month()))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(cal.isDateInToday(day) ? Color(hex: accentHex) : .secondary)
                            .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 6)
                        ForEach(appts(on: day)) { a in
                            HStack(spacing: 12) {
                                Text(a.time.formatted(.dateTime.hour().minute()))
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.secondary).frame(width: 44, alignment: .trailing)
                                Text(a.title).font(.system(size: 14, weight: .medium))
                                Spacer()
                            }
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(Color(.secondarySystemGroupedBackground))
                            Divider().padding(.leading, 76)
                        }
                    }
                }
                if days.allSatisfy({ appts(on: $0).isEmpty }) {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar").font(.system(size: 40)).foregroundColor(.secondary.opacity(0.3))
                        Text("Keine Termine in den nächsten 14 Tagen").font(.system(size: 14)).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 60)
                }
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

// MARK: - Pro Gate

struct ProGateView: View {
    @Binding var isPro: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "crown.fill")
                .font(.system(size: 56)).foregroundColor(Color(hex: "F59E0B"))
            VStack(spacing: 8) {
                Text("Buddy Pro")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("Schalte alle Tagesansichten und Premium-Funktionen frei.")
                    .font(.system(size: 15)).foregroundColor(.secondary)
                    .multilineTextAlignment(.center).padding(.horizontal, 32)
            }
            VStack(alignment: .leading, spacing: 12) {
                ForEach(["Morgen-Ansicht", "Wochen-Ansicht", "Monats-Kalender",
                         "Fokus-Modus", "Agenda-Ansicht"], id: \.self) { feature in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(Color(hex: "F59E0B"))
                        Text(feature).font(.system(size: 15))
                    }
                }
            }
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "F59E0B").opacity(0.08)))
            .padding(.horizontal, 24)
            Button {
                isPro = true; dismiss()
            } label: {
                Text("Jetzt freischalten")
                    .font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(colors: [Color(hex: "F59E0B"), Color(hex: "FBBF24")],
                                             startPoint: .leading, endPoint: .trailing)))
            }
            .padding(.horizontal, 24)
            Button("Abbrechen") { dismiss() }.foregroundColor(.secondary)
            Spacer()
        }
    }
}
