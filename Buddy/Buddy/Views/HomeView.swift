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
                        .onAppear { showGreeting = true }

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
        }
        .sheet(isPresented: $showTaskEdit) {
            TaskEditView(tasks: $viewModel.tasks)
        }
        .sheet(isPresented: $showHabitEdit) {
            HabitEditView(habits: $viewModel.habits)
        }
        } // end else
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
