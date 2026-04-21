//
//  HomeView.swift
//  Buddy
//
//  Created by Torben Lehneke on 19.04.26.
//

import SwiftUI

struct HomeView: View {
    @AppStorage("buddyName") private var buddyName = ""
    @StateObject private var viewModel = HomeViewModel()
    @State private var showGreeting = false
    @State private var showHabitEdit = false
    @State private var showTaskEdit = false
    @State private var showSettings = false
    @State private var showAllTasks = false
    @State private var showAllHabits = false
    @State private var showAppointments = false
    @State private var showNotes = false
    @State private var showShopping = false
    @State private var showDeadlines = false
    @State private var showDelegation = false
    @State private var showBirthdays = false
    @State private var showIdeas = false
    @State private var showProjects = false
    @State private var showDayPlan = false
    @State private var showMorningBriefing = false
    @State private var showEveningReview = false
    @State private var showCalendar = false
    @State private var showRoutines = false
    @State private var showStats = false
    @State private var showMultiDay = false
    @State private var showAssistant = false
    @State private var showChat = false
    @AppStorage("briefingShownDate") private var briefingShownDate = ""
    @AppStorage("eveningShownDate")  private var eveningShownDate  = ""
    @AppStorage("currentFocus") private var currentFocus = ""

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<10:  return "Guten Morgen! ☀️"
        case 10..<12: return "Guten Vormittag! 🌤"
        case 12..<14: return "Guten Mittag! 🌞"
        case 14..<18: return "Guten Nachmittag! 👋"
        case 18..<22: return "Guten Abend! 🌆"
        case 22..<24: return "Gute Nacht! 🌙"
        default:       return "Nachtaktiv? 🦉"
        }
    }

    private static let motivationalQuotes: [String] = [
        "Jeder neue Tag ist eine Chance, besser zu werden.",
        "Kleine Schritte führen zu großen Zielen.",
        "Fortschritt, nicht Perfektion.",
        "Beginne – der Rest folgt von selbst.",
        "Was du heute tust, entscheidet über morgen.",
        "Deine Gewohnheiten formen deine Zukunft.",
        "Energie folgt der Aufmerksamkeit.",
        "Du bist weiter, als du gestern warst.",
        "Routine schlägt Motivation auf lange Sicht.",
        "Disziplin ist die Brücke zwischen Wunsch und Wirklichkeit.",
        "Du bist die Summe deiner täglichen Entscheidungen.",
        "Wachstum beginnt am Rand deiner Komfortzone.",
        "Vergleiche dich nur mit dem, der du gestern warst.",
        "Konsequenz schlägt Talent.",
        "Dein einziger Konkurrent bist du selbst.",
        "Manchmal ist Weitermachen der mutigste Schritt.",
        "Fokus ist die Kunst, Nein zu sagen.",
        "Glaub an dich – andere tun es auch.",
        "Hab Geduld mit dir – Großes braucht Zeit.",
        "Auch der längste Weg beginnt mit dem ersten Schritt.",
        "Heute ist genug. Tu das Mögliche.",
        "Wer aufhört, besser zu werden, hat aufgehört, gut zu sein.",
        "Jede Gewohnheit ist ein Geschenk an dein zukünftiges Ich.",
        "Rückschläge sind Anlaufstrecken.",
        "Nicht die Umstände, sondern deine Reaktion zählt.",
        "Du schaffst alles, was du dir wirklich vornimmst.",
        "Ein erledigtes To-do ist ein Schritt nach vorne.",
        "Heute ist ein guter Tag, etwas Großes zu beginnen.",
        "Du hast heute schon mehr geschafft, als du denkst.",
        "Mach es – Halbherzigkeit bringt nichts."
    ]

    private var buddyMessage: String {
        let cal   = Calendar.current
        let hour  = cal.component(.hour, from: Date())
        let day   = cal.component(.day, from: Date())
        let total = viewModel.tasks.count + viewModel.habits.count
        let done  = viewModel.tasks.filter { $0.isDone }.count + viewModel.habits.filter { $0.isDone }.count

        if total == 0   { return "Leg los – füge heute deine ersten Ziele hinzu!" }
        if done == total { return "Alles erledigt! Du rockst das heute! 🎉" }

        let index = (hour + day) % Self.motivationalQuotes.count
        return Self.motivationalQuotes[index]
    }

    var body: some View {
        if buddyName.isEmpty {
            BuddyOnboardingView(buddyName: $buddyName)
        } else {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color(hex: "EEF2FF"), Color(hex: "E0E7FF"), Color(hex: "F5F3FF")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Floating chat button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button { showChat = true } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Mit Buddy sprechen")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 18).padding(.vertical, 13)
                            .background(
                                LinearGradient(colors: [Color(hex: "6C63FF"), Color(hex: "A78BFA")],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(Capsule())
                            .shadow(color: Color(hex: "6C63FF").opacity(0.45), radius: 14, x: 0, y: 6)
                        }
                        .padding(.trailing, 20).padding(.bottom, 24)
                    }
                }
                .zIndex(10)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // ── Buddy Hero ───────────────────────────────────
                        VStack(spacing: 0) {
                            BuddyFigure()

                            // Speech bubble
                            HStack(alignment: .top, spacing: 0) {
                                Spacer()
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(buddyMessage)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Color(hex: "5B54D6"))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(Color(.secondarySystemGroupedBackground))
                                        .shadow(color: Color(hex: "6C63FF").opacity(0.15), radius: 12, x: 0, y: 4)
                                )
                                .overlay(
                                    // Tail
                                    Image(systemName: "arrowtriangle.left.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(.secondarySystemGroupedBackground))
                                        .offset(x: -20, y: 8),
                                    alignment: .topLeading
                                )
                                .padding(.leading, 32)
                                .opacity(showGreeting ? 1 : 0)
                                .offset(x: showGreeting ? 0 : 20)
                                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: showGreeting)
                                Spacer()
                            }
                            .padding(.top, -12)
                        }
                        .padding(.top, 4)
                        .onAppear {
                            showGreeting = true
                            let today = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
                            let hour  = Calendar.current.component(.hour, from: Date())
                            if hour >= 5 && hour < 12 && briefingShownDate != today {
                                briefingShownDate = today
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { showMorningBriefing = true }
                            } else if hour >= 18 && hour < 23 && eveningShownDate != today {
                                eveningShownDate = today
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { showEveningReview = true }
                            }
                            SmartReminderService.shared.requestPermission()
                            SmartReminderService.shared.schedule(
                                tasks: viewModel.tasks,
                                habits: viewModel.habits,
                                appointments: viewModel.appointments,
                                name: buddyName
                            )
                        }

                        // ── Progress Strip ────────────────────────────────
                        ProgressStrip(
                            tasksDone: viewModel.tasks.filter { $0.isDone }.count,
                            tasksTotal: viewModel.tasks.count,
                            habitsDone: viewModel.habits.filter { $0.isDone }.count,
                            habitsTotal: viewModel.habits.count
                        )

                        // ── Day Overview ──────────────────────────────────
                        DayOverviewView(
                            openTasksCount: viewModel.openTasksCount,
                            openHabitsCount: viewModel.openHabitsCount
                        )

                        // ── Sekretär ─────────────────────────────────────
                        secretaryCards

                        // ── CTA ───────────────────────────────────────────
                        Button {
                            showTaskEdit = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("\(buddyName.isEmpty ? "Buddy" : buddyName), zeig mir, was heute ansteht")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "6C63FF"), Color(hex: "A78BFA")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: Color(hex: "6C63FF").opacity(0.35), radius: 10, x: 0, y: 4)
                        }

                        // ── Footer ────────────────────────────────────────
                        Text(Date().formatted(date: .complete, time: .omitted))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "9CA3AF"))
                            .padding(.bottom, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle(buddyName.isEmpty ? Constants.Text.appName : buddyName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "6C63FF"))
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showTaskEdit) {
            TasksView(viewModel: viewModel)
        }
        .sheet(isPresented: $showHabitEdit) {
            HabitsView(viewModel: viewModel)
        }
        .sheet(isPresented: $showAppointments) {
            AppointmentsView(viewModel: viewModel)
        }
        .sheet(isPresented: $showNotes) {
            NotesView(viewModel: viewModel)
        }
        .sheet(isPresented: $showShopping) {
            ShoppingView(viewModel: viewModel)
        }
        .sheet(isPresented: $showDeadlines) {
            DeadlinesView(viewModel: viewModel)
        }
        .sheet(isPresented: $showDelegation) {
            DelegationView(viewModel: viewModel)
        }
        .sheet(isPresented: $showBirthdays) {
            BirthdaysView(viewModel: viewModel)
        }
        .sheet(isPresented: $showIdeas) {
            IdeasView(viewModel: viewModel)
        }
        .sheet(isPresented: $showProjects) {
            ProjectsView(viewModel: viewModel)
        }
        .sheet(isPresented: $showDayPlan) {
            DayPlanView(viewModel: viewModel)
        }
        .sheet(isPresented: $showMorningBriefing) {
            MorningBriefingView(viewModel: viewModel)
        }
        .sheet(isPresented: $showEveningReview) {
            EveningReviewView(viewModel: viewModel)
        }
        .sheet(isPresented: $showCalendar) {
            CalendarView(viewModel: viewModel)
        }
        .sheet(isPresented: $showRoutines) {
            RoutinesView(viewModel: viewModel)
        }
        .sheet(isPresented: $showStats) {
            StatsView(viewModel: viewModel)
        }
        .sheet(isPresented: $showMultiDay) {
            MultiDayView(viewModel: viewModel)
        }
        .sheet(isPresented: $showAssistant) {
            BuddyAssistantView(viewModel: viewModel)
        }
        .sheet(isPresented: $showChat) {
            BuddyChatView(viewModel: viewModel)
        }
        } // end else
    }
}

// MARK: - Secretary Cards

extension HomeView {
    private var secretaryCards: some View {
        VStack(spacing: 12) {

            // ── Buddy Assistant (PRO) ─────────────────────────────────────
            Button { showAssistant = true } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(LinearGradient(colors: [Color(hex: "6C63FF"), Color(hex: "EC4899")],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 40, height: 40)
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 17, weight: .semibold)).foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text("Buddy Assistant")
                                .font(.system(size: 15, weight: .bold)).foregroundColor(.primary)
                            Text("PRO")
                                .font(.system(size: 9, weight: .bold)).foregroundColor(.white)
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(Color(hex: "6C63FF")).clipShape(Capsule())
                        }
                        let open = viewModel.tasks.filter { !$0.isDone }.count
                        Text(open > 5 ? "Überladen – Buddy hat Vorschläge" : open == 0 ? "Alles im Griff!" : "Prioritäten & Tagesziel ansehen")
                            .font(.system(size: 12)).foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold)).foregroundColor(Color(hex: "9CA3AF"))
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: Color(hex: "6C63FF").opacity(0.2), radius: 12, x: 0, y: 4))
            }
            .buttonStyle(.plain)

            // ── Tagesroutine ──────────────────────────────────────────────
            groupCard(label: "Tagesroutine", icon: "clock.fill", color: "F59E0B") {
                let h = Calendar.current.component(.hour, from: Date())
                groupRow(icon: "sun.max.fill", iconBg: "F59E0B", title: "Morgen-Briefing",
                         subtitle: h >= 5 && h < 12 ? "Briefing wartet" : "Tagesstart planen",
                         action: { showMorningBriefing = true })
                Divider().padding(.leading, 50)
                let openN = viewModel.tasks.filter { !$0.isDone }.count + viewModel.habits.filter { !$0.isDone }.count
                groupRow(icon: "list.bullet.clipboard.fill", iconBg: "6C63FF", title: "Smarter Tagesplan",
                         subtitle: openN == 0 ? "Alles erledigt!" : "\(openN) offen",
                         action: { showDayPlan = true })
                Divider().padding(.leading, 50)
                let due = viewModel.recurringTasks.filter { $0.isDueToday }
                let routineDone = due.filter { $0.isDoneToday }.count
                groupRow(icon: "repeat.circle.fill", iconBg: "F59E0B", title: "Routinen",
                         subtitle: due.isEmpty ? "Keine heute" : "\(routineDone)/\(due.count) erledigt",
                         action: { showRoutines = true })
                Divider().padding(.leading, 50)
                let evDone = viewModel.tasks.filter { $0.isDone }.count + viewModel.habits.filter { $0.isDone }.count
                let evTotal = viewModel.tasks.count + viewModel.habits.count
                groupRow(icon: "moon.stars.fill", iconBg: "4338CA", title: "Abend-Rückblick",
                         subtitle: evTotal == 0 ? "Tag reflektieren" : "\(evDone)/\(evTotal) erledigt",
                         action: { showEveningReview = true })
            }

            // ── Kalender & Termine ────────────────────────────────────────
            groupCard(label: "Kalender & Termine", icon: "calendar", color: "3B82F6") {
                let apptC = viewModel.todayAppointments.count
                groupRow(icon: "calendar", iconBg: "3B82F6", title: "Termine",
                         subtitle: apptC == 0 ? "Keine heute" : "\(apptC) heute",
                         action: { showAppointments = true })
                Divider().padding(.leading, 50)
                let calC = CalendarService.shared.todayEvents.count
                groupRow(icon: "applelogo", iconBg: "3B82F6", title: "Apple Kalender",
                         subtitle: calC == 0 ? "Verbinden" : "\(calC) Events",
                         action: { showCalendar = true })
                Divider().padding(.leading, 50)
                groupRow(icon: "rectangle.split.3x1.fill", iconBg: "0EA5E9", title: "Tagesansichten",
                         subtitle: "Woche · Monat · Fokus · Agenda",
                         action: { showMultiDay = true })
            }

            // ── Auswertungen & Erinnerungen ───────────────────────────────
            groupCard(label: "Auswertungen", icon: "chart.bar.xaxis", color: "8B5CF6") {
                let logN = viewModel.completionLog.count
                groupRow(icon: "chart.bar.xaxis", iconBg: "8B5CF6", title: "Auswertungen",
                         subtitle: logN == 0 ? "Noch keine Daten" : "\(logN) Einträge",
                         action: { showStats = true })
                Divider().padding(.leading, 50)
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(Color(hex: "10B981").opacity(0.15)).frame(width: 30, height: 30)
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 13, weight: .semibold)).foregroundColor(Color(hex: "10B981"))
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Smarte Erinnerungen").font(.system(size: 14, weight: .medium)).foregroundColor(.primary)
                        Text("Automatisch aktiv").font(.system(size: 12)).foregroundColor(.secondary)
                    }
                    Spacer()
                    Button {
                        SmartReminderService.shared.schedule(tasks: viewModel.tasks, habits: viewModel.habits,
                                                             appointments: viewModel.appointments, name: buddyName)
                    } label: {
                        Image(systemName: "arrow.clockwise").font(.system(size: 13)).foregroundColor(Color(hex: "10B981"))
                    }.buttonStyle(.plain)
                }
                .padding(.horizontal, 14).padding(.vertical, 10)
            }

            // ── Notizen, Ideen & Einkaufen ────────────────────────────────
            groupCard(label: "Schnellzugriff", icon: "tray.fill", color: "F97316") {
                let notesC = viewModel.notes.count
                groupRow(icon: "note.text", iconBg: "F97316", title: "Notizen",
                         subtitle: notesC == 0 ? "Keine" : "\(notesC) Notiz\(notesC == 1 ? "" : "en")",
                         action: { showNotes = true })
                Divider().padding(.leading, 50)
                let ideasC = viewModel.ideas.count
                groupRow(icon: "lightbulb.fill", iconBg: "FBBF24", title: "Ideen",
                         subtitle: ideasC == 0 ? "Keine" : "\(ideasC) Idee\(ideasC == 1 ? "" : "n")",
                         action: { showIdeas = true })
                Divider().padding(.leading, 50)
                let shopC = viewModel.shoppingItems.filter { !$0.isDone }.count
                groupRow(icon: "cart.fill", iconBg: "EC4899", title: "Einkaufsliste",
                         subtitle: shopC == 0 ? "Alles besorgt" : "\(shopC) offen",
                         action: { showShopping = true })
            }

            // ── Organisation ──────────────────────────────────────────────
            groupCard(label: "Organisation", icon: "folder.fill", color: "6366F1") {
                let deadOver = viewModel.deadlines.filter { $0.isOverdue }.count
                let deadC = viewModel.deadlines.count
                groupRow(icon: "flag.fill", iconBg: "EF4444", title: "Fristen",
                         subtitle: deadC == 0 ? "Keine" : deadOver > 0 ? "\(deadOver) überfällig" : "\(deadC) gespeichert",
                         action: { showDeadlines = true })
                Divider().padding(.leading, 50)
                let delC = viewModel.delegatedItems.filter { !$0.isDone }.count
                groupRow(icon: "person.2.fill", iconBg: "8B5CF6", title: "Delegiert",
                         subtitle: delC == 0 ? "Nichts offen" : "\(delC) offen",
                         action: { showDelegation = true })
                Divider().padding(.leading, 50)
                let projA = viewModel.projects.filter { $0.status == .active }.count
                let projC = viewModel.projects.count
                groupRow(icon: "folder.fill", iconBg: "6366F1", title: "Projekte",
                         subtitle: projC == 0 ? "Keine" : projA > 0 ? "\(projA) aktiv" : "\(projC) gespeichert",
                         action: { showProjects = true })
                Divider().padding(.leading, 50)
                let bdSoon = viewModel.birthdays.filter { $0.daysUntil <= 7 }.count
                let bdC = viewModel.birthdays.count
                groupRow(icon: "gift.fill", iconBg: "F472B6", title: "Geburtstage",
                         subtitle: bdSoon > 0 ? "\(bdSoon) bald" : bdC == 0 ? "Keine" : "\(bdC) gespeichert",
                         action: { showBirthdays = true })
            }

            // ── Fokus ─────────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "scope").font(.system(size: 12, weight: .semibold)).foregroundColor(Color(hex: "10B981"))
                    Text("Aktueller Fokus").font(.system(size: 13, weight: .semibold)).foregroundColor(Color(hex: "10B981"))
                }
                TextField("Womit beschäftige ich mich gerade?", text: $currentFocus)
                    .font(.system(size: 14)).foregroundColor(.primary)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3))
        }
    }

    // MARK: - Group Card Helpers

    private func groupCard<Content: View>(label: String, icon: String, color: String,
                                          @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 11, weight: .bold)).foregroundColor(Color(hex: color))
                Text(label).font(.system(size: 11, weight: .bold)).foregroundColor(Color(hex: color))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14).padding(.top, 12).padding(.bottom, 8)
            content()
        }
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color(.secondarySystemGroupedBackground))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3))
    }

    private func groupRow(icon: String, iconBg: String, title: String,
                          subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Color(hex: iconBg).opacity(0.15)).frame(width: 30, height: 30)
                    Image(systemName: icon).font(.system(size: 13, weight: .semibold)).foregroundColor(Color(hex: iconBg))
                }
                Text(title).font(.system(size: 14, weight: .medium)).foregroundColor(.primary)
                Spacer()
                Text(subtitle).font(.system(size: 12)).foregroundColor(.secondary)
                Image(systemName: "chevron.right").font(.system(size: 11)).foregroundColor(Color(hex: "D1D5DB"))
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Progress Strip

private struct ProgressStrip: View {
    let tasksDone: Int
    let tasksTotal: Int
    let habitsDone: Int
    let habitsTotal: Int

    private var totalDone: Int   { tasksDone + habitsDone }
    private var total: Int       { tasksTotal + habitsTotal }
    private var progress: Double { total == 0 ? 0 : Double(totalDone) / Double(total) }

    var body: some View {
        HStack(spacing: 16) {
            // Ring
            ZStack {
                Circle()
                    .stroke(Color(hex: "E0E7FF"), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "6C63FF"), Color(hex: "A78BFA")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: progress)
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "6C63FF"))
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 6) {
                Text("Tagesfortschritt")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "6B7280"))
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(hex: "E0E7FF"))
                            .frame(height: 8)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "6C63FF"), Color(hex: "A78BFA")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progress, height: 8)
                            .animation(.easeInOut(duration: 0.8), value: progress)
                    }
                }
                .frame(height: 8)
                Text("\(totalDone) von \(total) erledigt")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "9CA3AF"))
            }

            Spacer()

            // Quick stats
            VStack(spacing: 6) {
                StatBadge(value: tasksDone, total: tasksTotal, color: Color(hex: "6C63FF"), icon: "checkmark.circle.fill")
                StatBadge(value: habitsDone, total: habitsTotal, color: Color(hex: "FF6584"), icon: "flame.fill")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }
}

private struct StatBadge: View {
    let value: Int
    let total: Int
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(color)
            Text("\(value)/\(total)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "374151"))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Subviews

private struct BuddyFigure: View {
    @AppStorage("buddyGender") private var buddyGender = ""

    private var imageName: String { buddyGender.isEmpty ? "Buddy-mann" : buddyGender }

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 260)
            .shadow(color: Color(hex: "6C63FF").opacity(0.15), radius: 14, x: 0, y: 6)
    }
}

private struct SectionBlock<Content: View>: View {
    let title: String
    let icon: String
    let accent: Color
    let count: Int
    let total: Int
    var onEdit: (() -> Void)? = nil
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(accent)
                    .font(.system(size: 15, weight: .semibold))
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Spacer()
                if let onEdit {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(accent)
                            .padding(6)
                            .background(accent.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                if total > 0 {
                    Text("\(count)/\(total)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(accent.opacity(0.1))
                        .clipShape(Capsule())
                }
            }

            // Progress bar inside section
            if total > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(accent.opacity(0.12)).frame(height: 4)
                        Capsule()
                            .fill(accent)
                            .frame(width: geo.size.width * (Double(count) / Double(total)), height: 4)
                            .animation(.easeInOut(duration: 0.6), value: count)
                    }
                }
                .frame(height: 4)
            }

            content
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }
}

private struct EmptyHint: View {
    let text: String
    let icon: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "D1D5DB"))
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
}

// MARK: - Color Helper

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        var val: UInt64 = 0
        Scanner(string: h).scanHexInt64(&val)
        self.init(
            red: Double((val >> 16) & 0xFF) / 255,
            green: Double((val >> 8) & 0xFF) / 255,
            blue: Double(val & 0xFF) / 255
        )
    }
}

#Preview {
    HomeView()
}
