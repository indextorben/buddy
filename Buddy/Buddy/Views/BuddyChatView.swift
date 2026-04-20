// BuddyChatView.swift
import SwiftUI

struct BuddyChatView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("buddyName") private var buddyName = "Buddy"

    @State private var messages: [ChatMessage] = []
    @State private var input = ""
    @State private var isTyping = false
    @FocusState private var focused: Bool

    struct ChatMessage: Identifiable {
        let id = UUID()
        let text: String
        let isUser: Bool
        var date = Date()
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 10) {
                            ForEach(messages) { msg in
                                bubble(msg)
                                    .id(msg.id)
                            }
                            if isTyping { typingBubble }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .onChange(of: messages.count) { _ in
                        withAnimation { proxy.scrollTo(messages.last?.id, anchor: .bottom) }
                    }
                    .onChange(of: isTyping) { _ in
                        withAnimation { proxy.scrollTo("typing", anchor: .bottom) }
                    }
                }

                Divider()

                // Quick replies
                if messages.isEmpty || !isTyping {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            quickChip("Was steht heute an?")
                            quickChip("Neue Aufgabe")
                            quickChip("Wie läuft's?")
                            quickChip("Motivier mich!")
                            quickChip("Tagesplan zeigen")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }

                // Input bar
                HStack(spacing: 10) {
                    TextField("Schreib mit \(buddyName)…", text: $input)
                        .font(.system(size: 15))
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(Capsule())
                        .focused($focused)
                        .onSubmit { send() }
                    Button(action: send) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(input.trimmingCharacters(in: .whitespaces).isEmpty
                                            ? Color(hex: "D1D5DB") : Color(hex: "6C63FF"))
                    }
                    .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(Color(.systemGroupedBackground))
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle(buddyName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }.fontWeight(.semibold)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    buddyReply(opening())
                }
            }
        }
    }

    // MARK: - Subviews

    private func bubble(_ msg: ChatMessage) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            if msg.isUser { Spacer(minLength: 60) }
            if !msg.isUser {
                Circle()
                    .fill(LinearGradient(colors: [Color(hex: "6C63FF"), Color(hex: "A78BFA")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 28, height: 28)
                    .overlay(Text("B").font(.system(size: 13, weight: .bold)).foregroundColor(.white))
            }
            Text(msg.text)
                .font(.system(size: 15))
                .foregroundColor(msg.isUser ? .white : .primary)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(msg.isUser ? Color(hex: "6C63FF") : Color(.secondarySystemGroupedBackground))
                )
                .frame(maxWidth: .infinity, alignment: msg.isUser ? .trailing : .leading)
            if !msg.isUser { Spacer(minLength: 60) }
        }
    }

    private var typingBubble: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Circle()
                .fill(LinearGradient(colors: [Color(hex: "6C63FF"), Color(hex: "A78BFA")],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 28, height: 28)
                .overlay(Text("B").font(.system(size: 13, weight: .bold)).foregroundColor(.white))
            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Circle().fill(Color.secondary).frame(width: 7, height: 7)
                        .opacity(0.4)
                        .animation(.easeInOut(duration: 0.6).repeatForever().delay(Double(i) * 0.2), value: isTyping)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground)))
            Spacer(minLength: 60)
        }
        .id("typing")
    }

    private func quickChip(_ label: String) -> some View {
        Button { input = label; send() } label: {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "6C63FF"))
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Color(hex: "6C63FF").opacity(0.1))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Logic

    private func send() {
        let text = input.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        messages.append(ChatMessage(text: text, isUser: true))
        input = ""
        focused = false
        isTyping = true
        let delay = Double.random(in: 0.6...1.2)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            isTyping = false
            buddyReply(respond(to: text))
        }
    }

    private func buddyReply(_ text: String) {
        messages.append(ChatMessage(text: text, isUser: false))
    }

    // MARK: - NLP

    private func opening() -> String {
        let h = Calendar.current.component(.hour, from: Date())
        let greet = h < 12 ? "Guten Morgen" : h < 18 ? "Hey" : "Guten Abend"
        let open = viewModel.tasks.filter { !$0.isDone }.count + viewModel.habits.filter { !$0.isDone }.count
        return "\(greet)! Ich bin \(buddyName), dein persönlicher Assistent. Du hast heute noch \(open == 0 ? "nichts offen – Respekt! 🎉" : "\(open) offene Einträge.") Wie kann ich dir helfen?"
    }

    private func respond(to input: String) -> String {
        let t = input.lowercased()

        // Add task
        if t.hasPrefix("neue aufgabe") || t.hasPrefix("aufgabe:") || t.hasPrefix("füge aufgabe") || t.hasPrefix("add task") {
            let raw = input
                .replacingOccurrences(of: "neue aufgabe", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "aufgabe:", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "füge aufgabe", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "hinzu", with: "", options: .caseInsensitive)
                .trimmingCharacters(in: .whitespaces)
            if raw.isEmpty { return "Wie soll die Aufgabe heißen? Schreib einfach: Neue Aufgabe [Name]" }
            viewModel.tasks.append(Task(title: raw, isDone: false, priority: "Mittel"))
            return "✅ Aufgabe '\(raw)' wurde hinzugefügt!"
        }

        // Add habit
        if t.hasPrefix("neues habit") || t.hasPrefix("habit:") || t.hasPrefix("neue gewohnheit") {
            let raw = input
                .replacingOccurrences(of: "neues habit", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "habit:", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "neue gewohnheit", with: "", options: .caseInsensitive)
                .trimmingCharacters(in: .whitespaces)
            if raw.isEmpty { return "Wie soll das Habit heißen? Schreib: Neues Habit [Name]" }
            viewModel.habits.append(Habit(title: raw, isDone: false))
            return "🔥 Habit '\(raw)' wurde hinzugefügt!"
        }

        // Today overview
        if t.contains("heute") || t.contains("was steht an") || t.contains("tagesübersicht") || t.contains("what's up") {
            let openTasks = viewModel.tasks.filter { !$0.isDone }
            let openHabits = viewModel.habits.filter { !$0.isDone }
            let appts = viewModel.todayAppointments.count
            var reply = "📋 Heute für dich:\n"
            if openTasks.isEmpty && openHabits.isEmpty && appts == 0 {
                return "Heute ist dein Kalender leer – genieß den freien Tag! 🎉"
            }
            if !openTasks.isEmpty {
                reply += "• \(openTasks.count) Aufgabe\(openTasks.count == 1 ? "" : "n") offen"
                if let top = openTasks.first { reply += " (nächste: \(top.title))" }
                reply += "\n"
            }
            if !openHabits.isEmpty {
                reply += "• \(openHabits.count) Habit\(openHabits.count == 1 ? "" : "s") noch offen\n"
            }
            if appts > 0 { reply += "• \(appts) Termin\(appts == 1 ? "" : "e") heute\n" }
            return reply.trimmingCharacters(in: .newlines)
        }

        // Progress / how's it going
        if t.contains("wie läuft") || t.contains("fortschritt") || t.contains("progress") || t.contains("status") {
            let done = viewModel.tasks.filter { $0.isDone }.count + viewModel.habits.filter { $0.isDone }.count
            let total = viewModel.tasks.count + viewModel.habits.count
            guard total > 0 else { return "Du hast noch nichts eingetragen. Soll ich dir beim Planen helfen?" }
            let pct = Int(Double(done) / Double(total) * 100)
            let emoji = pct >= 80 ? "🔥" : pct >= 50 ? "💪" : "⚡️"
            return "\(emoji) Du bist bei \(pct)% – \(done) von \(total) erledigt. \(pct >= 80 ? "Stark!" : pct >= 50 ? "Weiter so!" : "Du packst das!")"
        }

        // Day plan
        if t.contains("tagesplan") || t.contains("plan") || t.contains("schedule") || t.contains("reihenfolge") {
            let plan = viewModel.generateDayPlan()
            guard !plan.isEmpty else { return "Dein Tagesplan ist leer. Füge erst Aufgaben hinzu!" }
            let top = plan.prefix(3).map { $0.title }.joined(separator: " → ")
            return "📅 Dein Tagesplan: \(top)\(plan.count > 3 ? " (+ \(plan.count - 3) weitere)" : "")"
        }

        // Most important task
        if t.contains("wichtigste") || t.contains("priorität") || t.contains("was zuerst") || t.contains("focus") || t.contains("fokus") {
            let rank = ["Hoch": 0, "Mittel": 1, "Niedrig": 2]
            let top = viewModel.tasks.filter { !$0.isDone }.sorted { (rank[$0.priority] ?? 1) < (rank[$1.priority] ?? 1) }.first
            if let t = top { return "🎯 Deine wichtigste Aufgabe jetzt: '\(t.title)' [\(t.priority)]" }
            return "Alle Aufgaben sind erledigt! 🎉"
        }

        // Motivation
        if t.contains("motivier") || t.contains("motivation") || t.contains("müde") || t.contains("keine lust") || t.contains("aufmunter") {
            let quotes = [
                "Du hast schon viel geschafft – ein Schritt mehr reicht heute! 💪",
                "Routine schlägt Motivation auf Dauer. Mach einfach weiter. 🔥",
                "Dein zukünftiges Ich wird dir dafür danken. ✨",
                "Jeder erledigte Task ist ein Beweis deiner Stärke. 💥",
                "Fang klein an – der Rest kommt von allein. 🚀"
            ]
            return quotes[Int.random(in: 0..<quotes.count)]
        }

        // Stats
        if t.contains("statistik") || t.contains("auswertung") || t.contains("streak") || t.contains("analyse") {
            let total = viewModel.completionLog.count
            return "📊 Du hast insgesamt \(total) Einträge abgehakt. Öffne Auswertungen für die vollen Stats!"
        }

        // Overload
        if t.contains("zu viel") || t.contains("überfordert") || t.contains("stress") || t.contains("zu vollgepackt") {
            let open = viewModel.tasks.filter { !$0.isDone }.count
            return "Ich verstehe. Du hast \(open) offene Aufgaben. Öffne den Buddy Assistant – ich helfe dir, die Liste auf das Wesentliche zu reduzieren. 🧘"
        }

        // Help
        if t.contains("hilf") || t.contains("help") || t.contains("was kannst du") || t.contains("befehle") {
            return "Das kann ich:\n• Neue Aufgabe [Name]\n• Neues Habit [Name]\n• Was steht heute an?\n• Wie läuft's?\n• Tagesplan zeigen\n• Wichtigste Aufgabe\n• Motivier mich!\n• Wie war mein Tag?"
        }

        // Evening review
        if t.contains("wie war mein tag") || t.contains("tagesrückblick") || t.contains("rückblick") {
            let done = viewModel.tasks.filter { $0.isDone }.count + viewModel.habits.filter { $0.isDone }.count
            let total = viewModel.tasks.count + viewModel.habits.count
            let pct = total > 0 ? Int(Double(done) / Double(total) * 100) : 0
            return "🌙 Tagesrückblick: \(done)/\(total) erledigt (\(pct)%). \(pct >= 80 ? "Hervorragender Tag!" : pct >= 50 ? "Solider Tag – morgen weiter!" : "Nicht alles geschafft, aber du warst dabei. Das zählt.")"
        }

        // Greeting
        if t.hasPrefix("hallo") || t.hasPrefix("hi") || t.hasPrefix("hey") || t == "guten morgen" || t == "guten abend" {
            return "Hey! 👋 Schön, dass du da bist. Was soll ich für dich tun?"
        }

        // Default
        let fallbacks = [
            "Das habe ich noch nicht ganz verstanden. Schreib 'Hilfe' für eine Liste meiner Fähigkeiten.",
            "Hmm, das ist neu für mich. Versuch's mit: 'Was steht heute an?' oder 'Neue Aufgabe [Name]'.",
            "Ich lerne noch. Aber ich versuche mein Bestes! 😅 Schreib 'Hilfe' für Befehle."
        ]
        return fallbacks[Int.random(in: 0..<fallbacks.count)]
    }
}
