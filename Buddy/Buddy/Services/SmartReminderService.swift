//  SmartReminderService.swift
import UserNotifications
import Foundation

final class SmartReminderService {
    static let shared = SmartReminderService()
    private init() {}

    private let apptPrefix = "smart_appt_"
    private let fixedIDs   = ["smart_habit", "smart_task", "smart_reschedule"]

    func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    func schedule(tasks: [Task], habits: [Habit], appointments: [Appointment], name: String) {
        let center = UNUserNotificationCenter.current()

        center.getPendingNotificationRequests { pending in
            let apptIDs = pending.map(\.identifier).filter { $0.hasPrefix(self.apptPrefix) }
            center.removePendingNotificationRequests(withIdentifiers: self.fixedIDs + apptIDs)

            let cal = Calendar.current
            let now = Date()

            // 1. Kein Habit erledigt → 10:00
            let doneHabits = habits.filter { $0.isDone }.count
            if !habits.isEmpty && doneHabits == 0,
               let t = cal.date(bySettingHour: 10, minute: 0, second: 0, of: now), t > now {
                self.add(id: "smart_habit",
                         title: "Hey, \(name)!",
                         body: "Du hast heute noch kein Habit erledigt – kurz Zeit?",
                         at: t)
            }

            // 2. Wichtigste Aufgabe offen → 13:00
            let rank = ["Hoch": 0, "Mittel": 1, "Niedrig": 2]
            if let top = tasks.filter({ !$0.isDone })
                              .sorted(by: { (rank[$0.priority] ?? 1) < (rank[$1.priority] ?? 1) })
                              .first,
               let t = cal.date(bySettingHour: 13, minute: 0, second: 0, of: now), t > now {
                self.add(id: "smart_task",
                         title: "Wichtige Aufgabe wartet!",
                         body: "Du hast \"\(top.title)\" noch nicht gestartet.",
                         at: t)
            }

            // 3. 30 min vor jedem Termin
            for appt in appointments {
                let fire = appt.time.addingTimeInterval(-30 * 60)
                guard fire > now else { continue }
                self.add(id: "\(self.apptPrefix)\(appt.id)",
                         title: "In 30 Minuten",
                         body: "Dein Termin: \(appt.title)",
                         at: fire)
            }

            // 4. Viele offene Aufgaben → 20:00
            let open = tasks.filter { !$0.isDone }.count
            if !tasks.isEmpty && Double(open) / Double(tasks.count) > 0.5,
               let t = cal.date(bySettingHour: 20, minute: 0, second: 0, of: now), t > now {
                self.add(id: "smart_reschedule",
                         title: "Heute war viel los!",
                         body: "Du hast noch \(open) offene Aufgaben. Willst du einige auf morgen verschieben?",
                         at: t)
            }
        }
    }

    private func add(id: String, title: String, body: String, at date: Date) {
        let content       = UNMutableNotificationContent()
        content.title     = title
        content.body      = body
        content.sound     = .default
        let comps         = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger       = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
