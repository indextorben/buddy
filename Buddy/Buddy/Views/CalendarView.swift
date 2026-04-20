//  CalendarView.swift
import SwiftUI
import EventKit

struct CalendarView: View {
    @ObservedObject var viewModel: HomeViewModel
    @StateObject private var cal = CalendarService.shared
    @Environment(\.dismiss) private var dismiss
    @AppStorage("accentColorHex") private var accentHex = "6C63FF"

    @State private var selectedDays = 7

    private var pendingTasks: [String] {
        let rank = ["Hoch": 0, "Mittel": 1, "Niedrig": 2]
        return viewModel.tasks
            .filter { !$0.isDone }
            .sorted { (rank[$0.priority] ?? 1) < (rank[$1.priority] ?? 1) }
            .map { $0.title }
    }

    // Merge CalendarEvents + manual Appointments into a unified timeline
    private var mergedToday: [TimelineItem] {
        var items: [TimelineItem] = cal.todayEvents.map {
            TimelineItem(id: $0.id, title: $0.title, subtitle: $0.calendarTitle,
                         start: $0.startDate, end: $0.endDate,
                         colorHex: $0.colorHex, kind: .calendar)
        }
        for appt in viewModel.todayAppointments {
            items.append(TimelineItem(id: appt.id.uuidString, title: appt.title, subtitle: "Eigener Termin",
                                     start: appt.time, end: appt.time.addingTimeInterval(3600),
                                     colorHex: "3B82F6", kind: .manual))
        }
        return items.sorted { $0.start < $1.start }
    }

    private var upcomingEvents: [CalendarEvent] {
        cal.fetchDays(selectedDays).filter {
            !Calendar.current.isDateInToday($0.startDate)
        }
    }

    private var needsPermission: Bool {
        let s = cal.authStatus
        return s == .notDetermined || s == .denied || s == .restricted
    }

    var body: some View {
        NavigationView {
            Group {
                if needsPermission {
                    permissionView
                } else {
                    calendarContent
                }
            }
            .navigationTitle("Kalender & Termine")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .fontWeight(.semibold).foregroundColor(Color(hex: accentHex))
                }
            }
            .task {
                if cal.authStatus == .fullAccess || cal.authStatus == .authorized {
                    cal.fetchToday()
                }
            }
        }
    }

    // MARK: - Permission

    private var permissionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 52)).foregroundColor(Color(hex: "3B82F6").opacity(0.6))
            VStack(spacing: 8) {
                Text("Kalender verbinden")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text("Buddy liest deinen Apple Kalender und zeigt Termine in deiner Tagesplanung an.")
                    .font(.system(size: 14)).foregroundColor(.secondary)
                    .multilineTextAlignment(.center).padding(.horizontal, 32)
            }
            Button {
                _Concurrency.Task { await cal.requestAccess() }
            } label: {
                Text("Zugriff erlauben")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(hex: "3B82F6")))
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Content

    private var calendarContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {

                // Heute – Timeline
                if !mergedToday.isEmpty || !pendingTasks.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("Heute", icon: "calendar", color: "3B82F6")
                        interleavedTimeline
                    }
                    .padding(16)
                    .background(card)
                }

                // Kommende Tage
                let upcoming = cal.fetchDays(selectedDays).filter {
                    !Calendar.current.isDateInToday($0.startDate)
                }
                if !upcoming.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            sectionLabel("Demnächst", icon: "clock", color: "6C63FF")
                            Spacer()
                            Picker("", selection: $selectedDays) {
                                Text("7 Tage").tag(7)
                                Text("14 Tage").tag(14)
                                Text("30 Tage").tag(30)
                            }
                            .pickerStyle(.menu)
                            .font(.system(size: 12))
                        }
                        ForEach(upcoming) { event in
                            HStack(spacing: 10) {
                                Circle().fill(Color(hex: event.colorHex)).frame(width: 8, height: 8)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(event.title).font(.system(size: 14, weight: .medium))
                                    Text("\(event.startDate.formatted(date: .abbreviated, time: .shortened)) · \(event.calendarTitle)")
                                        .font(.system(size: 11)).foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 3)
                        }
                    }
                    .padding(16).background(card)
                }

                if mergedToday.isEmpty && upcoming.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 40)).foregroundColor(.secondary.opacity(0.4))
                        Text("Keine Termine in den nächsten \(selectedDays) Tagen")
                            .font(.system(size: 14)).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 40)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    // Interleaved: Calendar events + tasks in free slots
    private var interleavedTimeline: some View {
        let plan = buildInterleavedPlan()
        return VStack(spacing: 8) {
            ForEach(plan, id: \.id) { item in
                HStack(spacing: 10) {
                    Text(item.start.formatted(.dateTime.hour().minute()))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.secondary).frame(width: 40, alignment: .trailing)
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 2).fill(Color(hex: item.colorHex))
                            .frame(width: 3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title).font(.system(size: 14, weight: .medium))
                                .foregroundColor(item.kind == .task ? .secondary : .primary)
                            if !item.subtitle.isEmpty {
                                Text(item.subtitle).font(.system(size: 11)).foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        if item.kind == .task {
                            Text("~45 min").font(.system(size: 10)).foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 10).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(hex: item.colorHex).opacity(item.kind == .task ? 0.05 : 0.10)))
                }
            }
        }
    }

    private func buildInterleavedPlan() -> [TimelineItem] {
        let result = mergedToday
        var cursor = Calendar.current.date(
            bySettingHour: max(8, Calendar.current.component(.hour, from: Date())),
            minute: 0, second: 0, of: Date()) ?? Date()

        var taskQ = pendingTasks
        var inserted: [TimelineItem] = []

        for event in mergedToday.sorted(by: { $0.start < $1.start }) {
            while !taskQ.isEmpty {
                let gap = event.start.timeIntervalSince(cursor)
                guard gap >= 60 * 60 else { break }
                let title = taskQ.removeFirst()
                let end   = cursor.addingTimeInterval(45 * 60)
                inserted.append(TimelineItem(id: UUID().uuidString, title: title, subtitle: "Aufgabe",
                                              start: cursor, end: end, colorHex: accentHex, kind: .task))
                cursor = end.addingTimeInterval(15 * 60)
            }
            cursor = event.end.addingTimeInterval(15 * 60)
        }
        for title in taskQ {
            let end = cursor.addingTimeInterval(45 * 60)
            inserted.append(TimelineItem(id: UUID().uuidString, title: title, subtitle: "Aufgabe",
                                          start: cursor, end: end, colorHex: accentHex, kind: .task))
            cursor = end.addingTimeInterval(15 * 60)
        }

        return (result + inserted).sorted { $0.start < $1.start }
    }

    private func sectionLabel(_ t: String, icon: String, color: String) -> some View {
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

// MARK: - Timeline Item

struct TimelineItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let start: Date
    let end: Date
    let colorHex: String
    let kind: Kind
    enum Kind { case calendar, manual, task }
}
