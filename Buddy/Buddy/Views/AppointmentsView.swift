//
//  AppointmentsView.swift
//  Buddy

import SwiftUI

struct AppointmentsView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var newTitle = ""
    @State private var newTime  = Date()
    @FocusState private var titleFocused: Bool

    private let cal = Calendar.current
    private var today: [Appointment] {
        viewModel.appointments.filter { cal.isDateInToday($0.time) }.sorted { $0.time < $1.time }
    }
    private var upcoming: [Appointment] {
        viewModel.appointments.filter { !cal.isDateInToday($0.time) && $0.time > Date() }.sorted { $0.time < $1.time }
    }

    var body: some View {
        NavigationView {
            List {
                Section("Heute") {
                    if today.isEmpty {
                        Text("Keine Termine heute")
                            .foregroundColor(.secondary).font(.subheadline)
                    } else {
                        ForEach(today) { row($0) }
                    }
                }

                if !upcoming.isEmpty {
                    Section("Demnächst") {
                        ForEach(upcoming) { row($0) }
                    }
                }

                Section("Neuer Termin") {
                    TextField("Titel", text: $newTitle).focused($titleFocused)
                    DatePicker("Zeit", selection: $newTime, displayedComponents: [.date, .hourAndMinute])
                    Button("Hinzufügen", action: add)
                        .foregroundColor(Color(hex: "3B82F6"))
                        .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Termine")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .fontWeight(.semibold).foregroundColor(Color(hex: "3B82F6"))
                }
            }
        }
    }

    @ViewBuilder private func row(_ appt: Appointment) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(appt.title).font(.system(size: 15, weight: .medium))
                Text(appt.time.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 12)).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 3)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                viewModel.appointments.removeAll { $0.id == appt.id }
            } label: { Label("Löschen", systemImage: "trash") }
        }
    }

    private func add() {
        let t = newTitle.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        withAnimation { viewModel.appointments.append(Appointment(title: t, time: newTime)) }
        newTitle = ""; titleFocused = false
    }
}
