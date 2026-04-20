//  CalendarService.swift
import EventKit
import UIKit
import Combine

@MainActor
final class CalendarService: ObservableObject {
    static let shared = CalendarService()
    private let store = EKEventStore()

    @Published var authStatus: EKAuthorizationStatus = .notDetermined
    @Published var todayEvents: [CalendarEvent] = []

    private init() {
        authStatus = EKEventStore.authorizationStatus(for: .event)
    }

    func requestAccess() async {
        do {
            if #available(iOS 17, *) {
                try await store.requestFullAccessToEvents()
            } else {
                try await store.requestAccess(to: .event)
            }
            authStatus = EKEventStore.authorizationStatus(for: .event)
            fetchToday()
        } catch {}
    }

    func fetchToday() {
        guard authStatus == .fullAccess || authStatus == .authorized else { return }
        let cal    = Calendar.current
        let start  = cal.startOfDay(for: Date())
        let end    = cal.date(byAdding: .day, value: 1, to: start) ?? start
        let pred   = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        todayEvents = store.events(matching: pred)
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }
            .map { event in
                let uiColor = event.calendar.cgColor.map { UIColor(cgColor: $0) } ?? UIColor.systemBlue
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
                uiColor.getRed(&r, green: &g, blue: &b, alpha: nil)
                let hex = String(format: "%02X%02X%02X", Int(r*255), Int(g*255), Int(b*255))
                return CalendarEvent(
                    id: event.eventIdentifier ?? UUID().uuidString,
                    title: event.title ?? "Termin",
                    startDate: event.startDate,
                    endDate: event.endDate,
                    calendarTitle: event.calendar.title,
                    colorHex: hex
                )
            }
    }

    func fetchDays(_ count: Int) -> [CalendarEvent] {
        guard authStatus == .fullAccess || authStatus == .authorized else { return [] }
        let cal   = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end   = cal.date(byAdding: .day, value: count, to: start) ?? start
        let pred  = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        return store.events(matching: pred)
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }
            .map { event in
                let uiColor = event.calendar.cgColor.map { UIColor(cgColor: $0) } ?? UIColor.systemBlue
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
                uiColor.getRed(&r, green: &g, blue: &b, alpha: nil)
                let hex = String(format: "%02X%02X%02X", Int(r*255), Int(g*255), Int(b*255))
                return CalendarEvent(
                    id: event.eventIdentifier ?? UUID().uuidString,
                    title: event.title ?? "Termin",
                    startDate: event.startDate,
                    endDate: event.endDate,
                    calendarTitle: event.calendar.title,
                    colorHex: hex
                )
            }
    }
}
