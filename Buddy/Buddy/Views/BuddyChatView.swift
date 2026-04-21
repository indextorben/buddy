// BuddyChatView.swift
import SwiftUI
import Combine
import Speech
import AVFoundation
import CoreLocation

// MARK: - Location Manager

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocation?
    @Published var cityName = ""
    @Published var authStatus: CLAuthorizationStatus = .notDetermined
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        authStatus = manager.authorizationStatus
    }

    func requestAndFetch() {
        if authStatus == .notDetermined { manager.requestWhenInUseAuthorization() }
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
        if let loc = locations.first {
            CLGeocoder().reverseGeocodeLocation(loc) { [weak self] p, _ in
                DispatchQueue.main.async { self?.cityName = p?.first?.locality ?? "" }
            }
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async { self.authStatus = manager.authorizationStatus }
    }
}

// MARK: - Speech Manager

final class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var transcript = ""
    @Published var isRecording = false
    @Published var isSpeaking = false
    @Published var permissionGranted = false

    var onSpeakingFinished: (() -> Void)?
    var onRecordingFinished: ((String) -> Void)?

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "de-DE"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async { self.permissionGranted = status == .authorized }
        }
        AVAudioSession.sharedInstance().requestRecordPermission { _ in }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.onSpeakingFinished?()
        }
    }

    func toggleRecording() {
        if audioEngine.isRunning { stopRecording() } else { startRecording() }
    }

    private func startRecording() {
        transcript = ""
        audioEngine = AVAudioEngine()   // fresh engine each time avoids stale format state

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .measurement,
                                  options: [.duckOthers, .defaultToSpeaker, .allowBluetooth])
        try? session.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let req = recognitionRequest else { return }
        req.shouldReportPartialResults = true

        recognitionTask = recognizer?.recognitionTask(with: req) { [weak self] result, error in
            if let result {
                DispatchQueue.main.async { self?.transcript = result.bestTranscription.formattedString }
            }
            if error != nil || result?.isFinal == true {
                let finalText = self?.transcript ?? ""
                self?.stopRecording()
                if !finalText.isEmpty {
                    DispatchQueue.main.async { self?.onRecordingFinished?(finalText) }
                }
            }
        }

        // Use session's hardware rate (always valid after setActive) instead of
        // querying engine format which may be 0 on a freshly created engine.
        let hwRate = max(session.sampleRate, 16000.0)
        guard let fmt = AVAudioFormat(standardFormatWithSampleRate: hwRate, channels: 1) else { return }
        let inputNode = audioEngine.inputNode
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: fmt) { [weak self] buf, _ in
            self?.recognitionRequest?.append(buf)
        }
        audioEngine.prepare()
        try? audioEngine.start()
        DispatchQueue.main.async { self.isRecording = true }
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        DispatchQueue.main.async { self.isRecording = false }
    }

    /// "female" or "male"
    var voiceGender: String = "female"

    func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let clean = text.unicodeScalars.filter { $0.properties.isEmoji == false || $0.value < 128 }
        let ttsText = String(String.UnicodeScalarView(clean)).trimmingCharacters(in: .whitespaces)
        let utterance = AVSpeechUtterance(string: ttsText.isEmpty ? text : ttsText)
        let deVoices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("de-DE") }
        // Known identifiers (device must have voice downloaded)
        let femaleIDs = ["com.apple.voice.enhanced.de-DE.Anna",
                         "com.apple.ttsbundle.Anna-compact",
                         "com.apple.ttsbundle.siri_female_de-DE_compact"]
        let maleIDs   = ["com.apple.voice.enhanced.de-DE.Markus",
                         "com.apple.ttsbundle.Markus-compact",
                         "com.apple.ttsbundle.siri_male_de-DE_compact"]
        let preferred = voiceGender == "male" ? maleIDs : femaleIDs
        let fallback  = voiceGender == "male" ? femaleIDs : maleIDs
        utterance.voice = preferred.compactMap { AVSpeechSynthesisVoice(identifier: $0) }.first
                       ?? fallback.compactMap { AVSpeechSynthesisVoice(identifier: $0) }.first
                       ?? deVoices.first(where: { $0.quality == .enhanced })
                       ?? AVSpeechSynthesisVoice(language: "de-DE")
        utterance.rate = 0.50
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        utterance.preUtteranceDelay = 0.05
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stopSpeaking() { synthesizer.stopSpeaking(at: .immediate) }
}

struct BuddyChatView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("buddyName") private var buddyName = "Buddy"

    @StateObject private var speech = SpeechManager()
    @StateObject private var locationManager = LocationManager()
    @AppStorage("buddyVoiceEnabled") private var voiceEnabled = true
    @AppStorage("buddyVoiceGender") private var voiceGender = "female"
    @State private var voiceMode = false

    @State private var messages: [ChatMessage] = []
    @State private var input = ""
    @State private var isTyping = false
    @FocusState private var focused: Bool

    struct ChatMessage: Identifiable, Codable {
        let id: UUID
        let text: String
        let isUser: Bool
        var date: Date
        init(text: String, isUser: Bool) {
            self.id = UUID(); self.text = text; self.isUser = isUser; self.date = Date()
        }
    }

    struct ChatSession: Identifiable, Codable {
        let id: UUID
        var createdAt: Date
        var messages: [ChatMessage]
        var preview: String { messages.first(where: { !$0.isUser })?.text ?? messages.first?.text ?? "Leerer Chat" }
    }

    private let sessionsKey = "buddy_chat_sessions"
    @State private var currentSessionID = UUID()
    @State private var showHistory = false

    private func allSessions() -> [ChatSession] {
        guard let data = UserDefaults.standard.data(forKey: sessionsKey),
              let s = try? JSONDecoder().decode([ChatSession].self, from: data) else { return [] }
        return s.sorted { $0.createdAt > $1.createdAt }
    }

    private func saveMessages() {
        var sessions = allSessions()
        if let idx = sessions.firstIndex(where: { $0.id == currentSessionID }) {
            sessions[idx].messages = messages
        } else {
            sessions.insert(ChatSession(id: currentSessionID, createdAt: Date(), messages: messages), at: 0)
        }
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: sessionsKey)
        }
    }

    private func loadMessages() {
        // Load most recent session
        if let session = allSessions().first {
            currentSessionID = session.id
            messages = session.messages
        }
    }

    private func loadSession(_ session: ChatSession) {
        currentSessionID = session.id
        messages = session.messages
    }

    private func newChat() {
        currentSessionID = UUID()
        messages = []
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

                // Status bar: speaking / listening / chips
                if speech.isSpeaking {
                    HStack(spacing: 10) {
                        HStack(spacing: 4) {
                            ForEach(0..<4) { i in
                                Capsule()
                                    .fill(Color(hex: "6C63FF"))
                                    .frame(width: 3, height: CGFloat([8, 14, 10, 12][i]))
                                    .animation(.easeInOut(duration: 0.4).repeatForever().delay(Double(i) * 0.1), value: speech.isSpeaking)
                            }
                        }
                        Text("\(buddyName) spricht…")
                            .font(.system(size: 13, weight: .medium)).foregroundColor(Color(hex: "6C63FF"))
                        Spacer()
                        Button { speech.stopSpeaking() } label: {
                            Text("Stopp").font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: "6C63FF"))
                        }.buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Color(hex: "6C63FF").opacity(0.06))
                } else if speech.isRecording {
                    HStack(spacing: 10) {
                        Circle().fill(Color.red).frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.5).repeatForever(), value: speech.isRecording)
                        Text(speech.transcript.isEmpty ? "Ich höre zu… sprich jetzt." : speech.transcript)
                            .font(.system(size: 13)).foregroundColor(.primary).lineLimit(2)
                        Spacer()
                    }
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Color.red.opacity(0.06))
                } else if !isTyping {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            quickChip("Was steht heute an?")
                            quickChip("Neue Aufgabe")
                            quickChip("Wie läuft's?")
                            quickChip("Motivier mich!")
                            quickChip("Tagesplan zeigen")
                        }
                        .padding(.horizontal, 16).padding(.vertical, 8)
                    }
                }

                // Input bar
                HStack(spacing: 8) {
                    // Mic button
                    Button {
                        if speech.isRecording {
                            speech.stopRecording()
                            if !speech.transcript.isEmpty {
                                input = speech.transcript
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { send() }
                            }
                        } else {
                            focused = false
                            speech.stopSpeaking()
                            speech.toggleRecording()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(speech.isRecording ? Color.red : Color(hex: "6C63FF").opacity(0.12))
                                .frame(width: 38, height: 38)
                            Image(systemName: speech.isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(speech.isRecording ? .white : Color(hex: "6C63FF"))
                        }
                    }
                    .buttonStyle(.plain)

                    TextField("Schreib oder sprich mit \(buddyName)…", text: $input)
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

                    // ChatGPT-style voice mode
                    Button {
                        voiceMode = true
                        speech.stopSpeaking()
                        speech.stopRecording()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            let prompt: String
                            if let last = messages.last(where: { !$0.isUser }) {
                                prompt = last.text
                            } else {
                                prompt = opening()
                                messages.append(ChatMessage(text: prompt, isUser: false))
                            }
                            speech.speak(prompt)
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [Color(hex: "6C63FF"), Color(hex: "A78BFA")],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 36, height: 36)
                            Image(systemName: "waveform")
                                .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12).padding(.vertical, 10)
                .background(Color(.systemGroupedBackground))
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle(buddyName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showHistory = true } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "6C63FF"))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button { newChat() } label: {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "6C63FF"))
                        }
                        Button("Fertig") {
                            speech.stopRecording()
                            speech.stopSpeaking()
                            dismiss()
                        }.fontWeight(.semibold)
                    }
                }
            }
            .onAppear {
                speech.requestPermissions()
                speech.voiceGender = voiceGender
                loadMessages()
            }
            .onChange(of: voiceGender) { speech.voiceGender = $0 }
            .onDisappear {
                speech.stopRecording()
                speech.stopSpeaking()
            }
            .sheet(isPresented: $showHistory) { historySheet }
            .fullScreenCover(isPresented: $voiceMode) {
                VoiceModeView(speech: speech, buddyName: buddyName, isTyping: $isTyping) { userText in
                    messages.append(ChatMessage(text: userText, isUser: true))
                    isTyping = true
                    let delay = Double.random(in: 0.6...1.0)
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        isTyping = false
                        let reply = respond(to: userText)
                        messages.append(ChatMessage(text: reply, isUser: false))
                        saveMessages()
                        speech.speak(reply)
                    }
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

    // MARK: - History Sheet

    private var historySheet: some View {
        NavigationView {
            let sessions = allSessions()
            Group {
                if sessions.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 44)).foregroundColor(.secondary)
                        Text("Noch keine gespeicherten Chats")
                            .font(.system(size: 15)).foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(sessions) { session in
                            Button {
                                loadSession(session)
                                showHistory = false
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(session.createdAt, style: .date)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.primary)
                                    Text(session.preview)
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { idx in
                            var s = allSessions()
                            s.remove(atOffsets: idx)
                            if let data = try? JSONEncoder().encode(s) {
                                UserDefaults.standard.set(data, forKey: sessionsKey)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Verlauf")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { showHistory = false }.fontWeight(.semibold)
                }
            }
        }
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

    private func buddyReply(_ text: String, speak: Bool = false) {
        guard !text.isEmpty else { return }
        messages.append(ChatMessage(text: text, isUser: false))
        saveMessages()
        if speak { speech.speak(text) }
    }

    // MARK: - NLP

    private func opening() -> String {
        let h = Calendar.current.component(.hour, from: Date())
        let open = viewModel.tasks.filter { !$0.isDone }.count + viewModel.habits.filter { !$0.isDone }.count
        let habits = viewModel.habits.filter { !$0.isDone }.count
        let appts = viewModel.todayAppointments.count

        switch h {
        case 5..<10:
            let brief = open == 0
                ? "Du hast heute einen freien Start – alle Aufgaben sind erledigt."
                : "Du hast heute \(open) Punkte offen\(appts > 0 ? " und \(appts) Termin\(appts == 1 ? "" : "e")" : "")."
            return "Guten Morgen! Ich bin bereit. \(brief) Womit soll ich dir heute helfen?"
        case 10..<12:
            return "Guten Vormittag! \(open == 0 ? "Alles läuft super – nichts offen." : "\(open) Dinge stehen noch aus.") Wie kann ich helfen?"
        case 12..<14:
            return "Guten Mittag! Kurze Mittagspause? Ich halte die Stellung. Du hast \(open == 0 ? "nichts offen" : "\(open) offene Punkte"). Was brauchst du?"
        case 14..<18:
            let habitNote = habits > 0 ? " Übrigens – \(habits) Habit\(habits == 1 ? " wartet" : "s warten") noch auf dich." : ""
            return "Hey! Schön, dass du da bist.\(habitNote) Womit kann ich dir helfen?"
        case 18..<23:
            let done = viewModel.tasks.filter { $0.isDone }.count + viewModel.habits.filter { $0.isDone }.count
            let total = viewModel.tasks.count + viewModel.habits.count
            let score = total > 0 ? "\(done) von \(total) erledigt" : "noch nichts eingetragen"
            return "Guten Abend! Heute: \(score). Soll ich dir beim Abend-Rückblick helfen oder noch etwas erledigen?"
        default:
            return "Hey, du bist spät dran! Ich bin trotzdem für dich da. Was liegt an?"
        }
    }

    // MARK: - Weather

    private func fetchWeather() {
        locationManager.requestAndFetch()
        // Poll until location arrives (max 8s)
        var attempts = 0
        func tryFetch() {
            attempts += 1
            if let loc = locationManager.location {
                let lat = loc.coordinate.latitude
                let lon = loc.coordinate.longitude
                let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=temperature_2m,apparent_temperature,weathercode,windspeed_10m,relative_humidity_2m&timezone=auto&forecast_days=1")!
                URLSession.shared.dataTask(with: url) { data, _, _ in
                    guard let data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let current = json["current"] as? [String: Any] else {
                        DispatchQueue.main.async {
                            self.messages.append(ChatMessage(text: "Wetterdaten konnten nicht geladen werden.", isUser: false))
                            self.saveMessages()
                        }
                        return
                    }
                    let temp   = current["temperature_2m"] as? Double ?? 0
                    let feels  = current["apparent_temperature"] as? Double ?? 0
                    let wind   = current["windspeed_10m"] as? Double ?? 0
                    let humid  = current["relative_humidity_2m"] as? Double ?? 0
                    let code   = current["weathercode"] as? Int ?? 0
                    let city   = self.locationManager.cityName
                    let desc   = Self.weatherDescription(code: code)
                    let reply  = "Wetter\(city.isEmpty ? "" : " in \(city)") heute:\n\(desc)\nTemperatur: \(Int(temp))°C (gefühlt \(Int(feels))°C)\nWind: \(Int(wind)) km/h · Luftfeuchte: \(Int(humid))%"
                    DispatchQueue.main.async {
                        self.messages.append(ChatMessage(text: reply, isUser: false))
                        self.saveMessages()
                    }
                }.resume()
            } else if attempts < 16 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { tryFetch() }
            } else {
                DispatchQueue.main.async {
                    self.messages.append(ChatMessage(text: "Standort konnte nicht ermittelt werden. Bitte Ortungsdienste aktivieren.", isUser: false))
                    self.saveMessages()
                }
            }
        }
        tryFetch()
    }

    private static func weatherDescription(code: Int) -> String {
        switch code {
        case 0:        return "Sonnig und klar"
        case 1...3:    return "Teilweise bewölkt"
        case 45, 48:   return "Nebelig"
        case 51...55:  return "Nieselregen"
        case 61...65:  return "Regen"
        case 71...75:  return "Schneefall"
        case 80...82:  return "Regenschauer"
        case 95:       return "Gewitter"
        case 96, 99:   return "Gewitter mit Hagel"
        default:       return "Wechselhaft"
        }
    }

    // MARK: - NLP helpers
    private func extract(_ input: String, removing keywords: [String]) -> String {
        var s = input
        for kw in keywords { s = s.replacingOccurrences(of: kw, with: "", options: .caseInsensitive) }
        return s.trimmingCharacters(in: .whitespaces)
    }

    private func respond(to input: String) -> String {
        let t = input.lowercased()
        let cal = Calendar.current

        // MARK: Wetter
        if t.contains("wetter") || t.contains("temperatur") || t.contains("regen") || t.contains("sonnig") || t.contains("schnee") || t.contains("wie warm") || t.contains("wie kalt") || t.contains("weather") {
            switch locationManager.authStatus {
            case .denied, .restricted:
                return "Ortungsdienste sind deaktiviert. Bitte in den Einstellungen aktivieren, damit ich das Wetter abrufen kann."
            default:
                messages.append(ChatMessage(text: "Einen Moment, ich hole das Wetter für dich...", isUser: false))
                saveMessages()
                fetchWeather()
                return ""   // empty → no second bubble; fetchWeather appends its own
            }
        }

        // MARK: Greeting / Smalltalk
        let greetings = ["hallo","hi","hey","moin","servus","guten morgen","guten tag","guten abend","na","jo"]
        if greetings.contains(where: { t == $0 || t.hasPrefix($0 + " ") || t.hasPrefix($0 + ",") }) {
            let replies = [
                "Hey! Schön, dass du da bist. Wie kann ich dir helfen?",
                "Hallo! Was liegt heute an?",
                "Moin! Ich bin bereit. Was darf ich für dich tun?"
            ]
            return replies[Int.random(in: 0..<replies.count)]
        }
        if t.contains("wie geht") || t.contains("wie läufts") || t.contains("wie gehts") || t.contains("alles gut") || t.contains("alles okay") {
            let open = viewModel.tasks.filter { !$0.isDone }.count + viewModel.habits.filter { !$0.isDone }.count
            return open == 0
                ? "Mir geht's super – und dir auch, du hast alles erledigt!"
                : "Gut! Du hast noch \(open) offene Punkte – soll ich helfen?"
        }
        if t.contains("danke") || t.contains("thx") || t.contains("thanks") {
            return ["Gerne! Immer für dich da.", "Kein Problem!", "Jederzeit!"][Int.random(in: 0..<3)]
        }
        if t.contains("tschüss") || t.contains("ciao") || t.contains("bye") || t.contains("bis dann") {
            return "Bis bald! Pass auf dich auf."
        }

        // MARK: Aufgaben
        if t.contains("aufgabe") || t.contains("task") || t.contains("todo") {

            // Erledigen
            if t.contains("erledigt") || t.contains("fertig") || t.contains("abhaken") || t.contains("done") {
                let name = extract(input, removing: ["aufgabe","erledigt","fertig","abhaken","als","markieren","done","task"]).lowercased()
                if let idx = viewModel.tasks.firstIndex(where: { !$0.isDone && $0.title.lowercased().contains(name) && !name.isEmpty }) {
                    viewModel.toggleTask(viewModel.tasks[idx])
                    return "Aufgabe '\(viewModel.tasks[idx].title)' als erledigt markiert!"
                }
                // alle
                if name.isEmpty || t.contains("alle") {
                    let open = viewModel.tasks.filter { !$0.isDone }
                    open.forEach { viewModel.toggleTask($0) }
                    return "\(open.count) Aufgaben als erledigt markiert!"
                }
                return "Aufgabe nicht gefunden. Bitte genauer angeben."
            }

            // Löschen
            if t.contains("lösch") || t.contains("entfern") || t.contains("delete") {
                let name = extract(input, removing: ["aufgabe","löschen","lösch","entfernen","entfern","delete","task"]).lowercased()
                if let idx = viewModel.tasks.firstIndex(where: { $0.title.lowercased().contains(name) && !name.isEmpty }) {
                    let title = viewModel.tasks[idx].title
                    viewModel.tasks.remove(at: idx)
                    return "Aufgabe '\(title)' gelöscht."
                }
                return "Aufgabe nicht gefunden."
            }

            // Priorität ändern
            if t.contains("priorität") || t.contains("wichtig") {
                let prio: String = t.contains("hoch") ? "Hoch" : t.contains("niedrig") ? "Niedrig" : "Mittel"
                let name = extract(input, removing: ["aufgabe","priorität","setze","auf","hoch","mittel","niedrig","wichtig"]).lowercased()
                if let idx = viewModel.tasks.firstIndex(where: { $0.title.lowercased().contains(name) && !name.isEmpty }) {
                    viewModel.tasks[idx].priority = prio
                    return "Priorität von '\(viewModel.tasks[idx].title)' auf \(prio) gesetzt."
                }
            }

            // Auflisten
            if t.contains("zeig") || t.contains("list") || t.contains("alle") || t.contains("welche") || t.contains("was") {
                let open = viewModel.tasks.filter { !$0.isDone }
                if open.isEmpty { return "Keine offenen Aufgaben – alles erledigt!" }
                return "Offene Aufgaben:\n" + open.prefix(8).map { "• \($0.title) [\($0.priority)]" }.joined(separator: "\n")
            }

            // Hinzufügen
            let raw = extract(input, removing: ["neue aufgabe","aufgabe hinzufügen","aufgabe:","füge aufgabe","aufgabe","hinzu","add task","task"])
            if raw.isEmpty { return "Wie soll die Aufgabe heißen?" }
            let prio: String = t.contains("hoch") ? "Hoch" : t.contains("niedrig") ? "Niedrig" : "Mittel"
            viewModel.tasks.append(Task(title: raw, isDone: false, priority: prio))
            return "Aufgabe '\(raw)' [\(prio)] hinzugefügt!"
        }

        // MARK: Habits
        if t.contains("habit") || t.contains("gewohnheit") || t.contains("routine") {

            if t.contains("erledigt") || t.contains("fertig") || t.contains("abhaken") || t.contains("done") {
                let name = extract(input, removing: ["habit","gewohnheit","erledigt","fertig","abhaken","done"]).lowercased()
                if let idx = viewModel.habits.firstIndex(where: { !$0.isDone && $0.title.lowercased().contains(name) && !name.isEmpty }) {
                    viewModel.toggleHabit(viewModel.habits[idx])
                    return "Habit '\(viewModel.habits[idx].title)' abgehakt!"
                }
                if name.isEmpty || t.contains("alle") {
                    let open = viewModel.habits.filter { !$0.isDone }
                    open.forEach { viewModel.toggleHabit($0) }
                    return "\(open.count) Habits abgehakt!"
                }
                return "Habit nicht gefunden."
            }

            if t.contains("lösch") || t.contains("entfern") {
                let name = extract(input, removing: ["habit","gewohnheit","löschen","lösch","entfernen","entfern"]).lowercased()
                if let idx = viewModel.habits.firstIndex(where: { $0.title.lowercased().contains(name) && !name.isEmpty }) {
                    let title = viewModel.habits[idx].title
                    viewModel.habits.remove(at: idx)
                    return "Habit '\(title)' gelöscht."
                }
                return "Habit nicht gefunden."
            }

            if t.contains("zeig") || t.contains("list") || t.contains("alle") || t.contains("welche") {
                let open = viewModel.habits.filter { !$0.isDone }
                if open.isEmpty { return "Alle Habits für heute erledigt!" }
                return "Offene Habits:\n" + open.prefix(8).map { "• \($0.title)" }.joined(separator: "\n")
            }

            let raw = extract(input, removing: ["neues habit","neues","habit:","habit","gewohnheit","neue gewohnheit","hinzu"])
            if raw.isEmpty { return "Wie soll das Habit heißen?" }
            viewModel.habits.append(Habit(title: raw, isDone: false))
            return "Habit '\(raw)' hinzugefügt!"
        }

        // MARK: Notizen
        if t.contains("notiz") || t.contains("note") {
            if t.contains("zeig") || t.contains("list") || t.contains("alle") || t.contains("welche") {
                if viewModel.notes.isEmpty { return "Du hast noch keine Notizen." }
                return "Notizen:\n" + viewModel.notes.prefix(6).map { "• \($0.text)" }.joined(separator: "\n")
            }
            if t.contains("lösch") || t.contains("entfern") {
                let name = extract(input, removing: ["notiz","note","löschen","lösch","entfernen","entfern"]).lowercased()
                if let idx = viewModel.notes.firstIndex(where: { $0.text.lowercased().contains(name) && !name.isEmpty }) {
                    viewModel.notes.remove(at: idx)
                    return "Notiz gelöscht."
                }
                return "Notiz nicht gefunden."
            }
            let raw = extract(input, removing: ["neue notiz","notiz:","notiz","note hinzufügen","note","hinzu","schreib"])
            if raw.isEmpty { return "Was soll ich notieren?" }
            viewModel.notes.append(Note(text: raw))
            return "Notiz gespeichert: '\(raw)'"
        }

        // MARK: Einkauf / Shopping
        if t.contains("einkauf") || t.contains("shopping") || t.contains("einkaufsliste") || t.contains("kaufen") {
            if t.contains("zeig") || t.contains("list") || t.contains("alle") || t.contains("was") {
                let open = viewModel.shoppingItems.filter { !$0.isDone }
                if open.isEmpty { return "Die Einkaufsliste ist leer." }
                return "Einkaufsliste:\n" + open.map { "• \($0.title)" }.joined(separator: "\n")
            }
            if t.contains("erledigt") || t.contains("gekauft") || t.contains("abhaken") {
                let name = extract(input, removing: ["einkauf","shopping","erledigt","gekauft","abhaken","item"]).lowercased()
                if let idx = viewModel.shoppingItems.firstIndex(where: { !$0.isDone && $0.title.lowercased().contains(name) && !name.isEmpty }) {
                    viewModel.shoppingItems[idx].isDone = true
                    return "'\(viewModel.shoppingItems[idx].title)' als gekauft markiert."
                }
            }
            let raw = extract(input, removing: ["einkaufsliste","einkauf","shopping","kaufen","hinzufügen","hinzu","item","add"])
            if raw.isEmpty { return "Was soll ich auf die Liste setzen?" }
            viewModel.shoppingItems.append(ShoppingItem(title: raw))
            return "'\(raw)' zur Einkaufsliste hinzugefügt."
        }

        // MARK: Deadlines / Fristen
        if t.contains("deadline") || t.contains("frist") || t.contains("fällig") || t.contains("abgabe") {
            if t.contains("zeig") || t.contains("list") || t.contains("alle") || t.contains("welche") {
                if viewModel.deadlines.isEmpty { return "Keine Deadlines eingetragen." }
                let fmt = DateFormatter(); fmt.dateStyle = .short; fmt.timeStyle = .none
                let sorted = viewModel.deadlines.sorted { $0.dueDate < $1.dueDate }
                return "Deadlines:\n" + sorted.prefix(6).map {
                    "• \($0.title) – \(fmt.string(from: $0.dueDate))\($0.isOverdue ? " ❗️überfällig" : $0.isUrgent ? " ⚠️ bald" : "")"
                }.joined(separator: "\n")
            }
            // Überfällige
            if t.contains("überfällig") {
                let overdue = viewModel.deadlines.filter { $0.isOverdue }
                if overdue.isEmpty { return "Keine überfälligen Deadlines." }
                return "Überfällig:\n" + overdue.map { "• \($0.title)" }.joined(separator: "\n")
            }
        }

        // MARK: Delegiert
        if t.contains("delegiert") || t.contains("delegier") || t.contains("delegat") || t.contains("weitergegeben") || t.contains("jemand") && t.contains("übergeben") {
            if t.contains("zeig") || t.contains("list") || t.contains("alle") || t.contains("welche") {
                if viewModel.delegatedItems.isEmpty { return "Keine delegierten Aufgaben." }
                return "Delegiert:\n" + viewModel.delegatedItems.prefix(6).map { "• \($0.title) → \($0.person)" }.joined(separator: "\n")
            }
        }

        // MARK: Projekte
        if t.contains("projekt") || t.contains("project") {
            if t.contains("zeig") || t.contains("list") || t.contains("alle") || t.contains("welche") {
                if viewModel.projects.isEmpty { return "Keine Projekte vorhanden." }
                return "Projekte:\n" + viewModel.projects.map { "• \($0.title) [\($0.status.rawValue)]" }.joined(separator: "\n")
            }
            let raw = extract(input, removing: ["neues projekt","projekt:","projekt","project","hinzu","erstell","new"])
            if !raw.isEmpty {
                viewModel.projects.append(Project(title: raw))
                return "Projekt '\(raw)' erstellt."
            }
        }

        // MARK: Ideen
        if t.contains("idee") || t.contains("idea") || t.contains("einfal") {
            if t.contains("zeig") || t.contains("list") || t.contains("alle") || t.contains("welche") {
                if viewModel.ideas.isEmpty { return "Noch keine Ideen gespeichert." }
                return "Ideen:\n" + viewModel.ideas.prefix(6).map { "• \($0.text)" }.joined(separator: "\n")
            }
            let raw = extract(input, removing: ["neue idee","idee:","idee","idea","einfal","notier","hinzu"])
            if raw.isEmpty { return "Was ist deine Idee?" }
            viewModel.ideas.append(Idea(text: raw))
            return "Idee gespeichert: '\(raw)'"
        }

        // MARK: Termine / Appointments
        if t.contains("termin") || t.contains("appointment") || t.contains("meeting") || t.contains("kalender") {
            if t.contains("heute") || t.contains("zeig") || t.contains("list") || t.contains("welche") || t.contains("wann") {
                let appts = viewModel.todayAppointments
                if appts.isEmpty { return "Heute keine Termine." }
                let fmt = DateFormatter(); fmt.timeStyle = .short; fmt.dateStyle = .none
                return "Termine heute:\n" + appts.map { "• \($0.title) um \(fmt.string(from: $0.time))" }.joined(separator: "\n")
            }
            // Nächster Termin
                if t.contains("nächst") || t.contains("next") {
                let upcoming = viewModel.appointments.filter { $0.time > Date() }.sorted { $0.time < $1.time }
                guard let next = upcoming.first else { return "Keine bevorstehenden Termine." }
                let fmt = DateFormatter(); fmt.dateStyle = .short; fmt.timeStyle = .short
                return "Nächster Termin: '\(next.title)' am \(fmt.string(from: next.time))"
            }
        }

        // MARK: Geburtstage
        if t.contains("geburtstag") || t.contains("birthday") {
            let upcoming = viewModel.birthdays.sorted { $0.daysUntil < $1.daysUntil }
            if upcoming.isEmpty { return "Keine Geburtstage gespeichert." }
            let next5 = upcoming.prefix(5).map {
                $0.daysUntil == 0 ? "• \($0.name) – heute!" : "• \($0.name) – in \($0.daysUntil) Tag\($0.daysUntil == 1 ? "" : "en")"
            }.joined(separator: "\n")
            return "Geburtstage:\n" + next5
        }

        // MARK: Tagesübersicht
        if t.contains("übersicht") || t.contains("was steht an") || t.contains("tagesübersicht") || t.contains("what's up") || (t.contains("heute") && !t.contains("termin")) {
            let openTasks = viewModel.tasks.filter { !$0.isDone }
            let openHabits = viewModel.habits.filter { !$0.isDone }
            let appts = viewModel.todayAppointments.count
            if openTasks.isEmpty && openHabits.isEmpty && appts == 0 {
                return "Heute ist alles frei – genieß den Tag!"
            }
            var reply = "Heute für dich:\n"
            if !openTasks.isEmpty {
                reply += "• \(openTasks.count) Aufgabe\(openTasks.count == 1 ? "" : "n") offen"
                if let top = openTasks.first { reply += " (nächste: \(top.title))" }
                reply += "\n"
            }
            if !openHabits.isEmpty { reply += "• \(openHabits.count) Habit\(openHabits.count == 1 ? "" : "s") offen\n" }
            if appts > 0 { reply += "• \(appts) Termin\(appts == 1 ? "" : "e") heute\n" }
            return reply.trimmingCharacters(in: .newlines)
        }

        // MARK: Tagesplan
        if t.contains("tagesplan") || t.contains("plan") || t.contains("schedule") || t.contains("reihenfolge") || t.contains("zeitplan") {
            let plan = viewModel.generateDayPlan()
            guard !plan.isEmpty else { return "Tagesplan leer. Füge erst Aufgaben hinzu!" }
            let fmt = DateFormatter(); fmt.timeStyle = .short; fmt.dateStyle = .none
            let lines = plan.prefix(5).map { "• \(fmt.string(from: $0.startTime)) \($0.title)" }.joined(separator: "\n")
            return "Dein Tagesplan:\n\(lines)\(plan.count > 5 ? "\n… und \(plan.count-5) weitere" : "")"
        }

        // MARK: Priorität / Fokus
        if t.contains("wichtigste") || t.contains("was zuerst") || t.contains("fokus") || t.contains("focus") || (t.contains("priorität") && !t.contains("aufgabe")) {
            let rank = ["Hoch": 0, "Mittel": 1, "Niedrig": 2]
            let top = viewModel.tasks.filter { !$0.isDone }.sorted { (rank[$0.priority] ?? 1) < (rank[$1.priority] ?? 1) }.first
            if let task = top { return "Deine wichtigste Aufgabe: '\(task.title)' [\(task.priority)]" }
            return "Alle Aufgaben erledigt!"
        }

        // MARK: Fortschritt / Status
        if t.contains("wie läuft") || t.contains("fortschritt") || t.contains("progress") || t.contains("status") || t.contains("wie steh") {
            let done = viewModel.tasks.filter { $0.isDone }.count + viewModel.habits.filter { $0.isDone }.count
            let total = viewModel.tasks.count + viewModel.habits.count
            guard total > 0 else { return "Noch nichts eingetragen. Soll ich dir beim Planen helfen?" }
            let pct = Int(Double(done) / Double(total) * 100)
            return "\(pct >= 80 ? "Stark!" : pct >= 50 ? "Weiter so!" : "Du packst das!") \(pct)% – \(done) von \(total) erledigt."
        }

        // MARK: Streak / Statistik
        if t.contains("statistik") || t.contains("auswertung") || t.contains("streak") || t.contains("analyse") || t.contains("wie oft") {
            let total = viewModel.completionLog.count
            let last7 = (0..<7).compactMap { cal.date(byAdding: .day, value: -$0, to: cal.startOfDay(for: Date())) }
            var streak = 0
            for day in last7.reversed() {
                if viewModel.completionLog.contains(where: { cal.isDate($0.date, inSameDayAs: day) }) { streak += 1 } else { break }
            }
            return "Statistik: \(total) Einträge insgesamt, aktueller Streak: \(streak) Tag\(streak == 1 ? "" : "e")."
        }

        // MARK: Tagesrückblick
        if t.contains("rückblick") || t.contains("wie war mein tag") || t.contains("abend") && t.contains("zusammenfassung") {
            let done = viewModel.tasks.filter { $0.isDone }.count + viewModel.habits.filter { $0.isDone }.count
            let total = viewModel.tasks.count + viewModel.habits.count
            let pct = total > 0 ? Int(Double(done) / Double(total) * 100) : 0
            return "Tagesrückblick: \(done)/\(total) erledigt (\(pct)%). \(pct >= 80 ? "Hervorragender Tag!" : pct >= 50 ? "Solider Tag!" : "Morgen neu anpacken!")"
        }

        // MARK: Überlastet / Stress
        if t.contains("zu viel") || t.contains("überfordert") || t.contains("stress") || t.contains("überwältigt") {
            let open = viewModel.tasks.filter { !$0.isDone }
            let low = open.filter { $0.priority == "Niedrig" }
            let reply = "Du hast \(open.count) offene Aufgaben.\(low.isEmpty ? "" : " Ich würde '\(low.prefix(2).map(\.title).joined(separator: "' und '"))' erst morgen angehen.") Fokus auf das Wichtigste!"
            return reply
        }

        // MARK: Motivation
        if t.contains("motivier") || t.contains("motivation") || t.contains("müde") || t.contains("keine lust") || t.contains("aufmunter") || t.contains("push") {
            let quotes = [
                "Routine schlägt Motivation auf Dauer. Einfach anfangen.",
                "Dein zukünftiges Ich wird dir dafür danken.",
                "Jeder erledigte Task ist ein Beweis deiner Stärke.",
                "Fang klein an – der Rest kommt von allein.",
                "Du hast schon viel geschafft – ein Schritt mehr reicht heute."
            ]
            return quotes[Int.random(in: 0..<quotes.count)]
        }

        // MARK: Hilfe
        if t.contains("hilf") || t.contains("help") || t.contains("was kannst du") || t.contains("befehle") || t.contains("fähigkeiten") {
            return """
            Das kann ich:
            • Aufgaben: hinzufügen, erledigen, löschen, auflisten, Priorität setzen
            • Habits: hinzufügen, abhaken, löschen, auflisten
            • Notizen: speichern, anzeigen, löschen
            • Einkaufsliste: hinzufügen, anzeigen, abhaken
            • Deadlines, Projekte, Ideen: anzeigen
            • Delegierte Aufgaben: anzeigen
            • Termine & Geburtstage: anzeigen
            • Tagesplan generieren
            • Fortschritt & Streaks anzeigen
            • Tagesrückblick
            • Motivieren
            """
        }

        // Default
        let fallbacks = [
            "Das habe ich noch nicht ganz verstanden. Sag 'Hilfe' für alle Fähigkeiten.",
            "Kannst du das anders formulieren? Zum Beispiel: 'Neue Aufgabe Sport' oder 'Zeig meine Habits'.",
            "Hmm, das ist neu für mich. Versuch: 'Was steht heute an?' oder 'Zeig meine Notizen'."
        ]
        return fallbacks[Int.random(in: 0..<fallbacks.count)]
    }
}

// MARK: - Voice Mode (ChatGPT-style)

struct VoiceModeView: View {
    @ObservedObject var speech: SpeechManager
    let buddyName: String
    @Binding var isTyping: Bool
    let onUserSpoke: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var pulse = false
    @State private var ripple = false

    private var statusText: String {
        if isTyping { return "Denke nach…" }
        if speech.isSpeaking { return "\(buddyName) spricht…" }
        if speech.isRecording {
            return speech.transcript.isEmpty ? "Ich höre zu…" : speech.transcript
        }
        return "Tippe auf den Orb zum Sprechen"
    }

    private var orbColors: [Color] {
        if speech.isSpeaking { return [Color(hex: "A78BFA"), Color(hex: "6C63FF"), Color(hex: "4338CA")] }
        if speech.isRecording { return [Color(hex: "6EE7B7"), Color(hex: "10B981"), Color(hex: "059669")] }
        if isTyping { return [Color(hex: "FCD34D"), Color(hex: "F59E0B"), Color(hex: "D97706")] }
        return [Color(hex: "818CF8"), Color(hex: "6366F1"), Color(hex: "4F46E5")]
    }

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            LinearGradient(colors: [Color(hex: "0F0A1E"), Color.black],
                           startPoint: .top, endPoint: .bottom).ignoresSafeArea()

            VStack(spacing: 48) {
                Spacer()

                // Orb
                ZStack {
                    // Ripple rings (listening)
                    if speech.isRecording {
                        ForEach(0..<3) { i in
                            Circle()
                                .stroke(Color(hex: "10B981").opacity(0.25 - Double(i) * 0.07), lineWidth: 1.5)
                                .frame(width: 180 + CGFloat(i * 50))
                                .scaleEffect(ripple ? 1.0 : 0.85)
                                .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)
                                    .delay(Double(i) * 0.35), value: ripple)
                        }
                    }
                    // Outer glow
                    Circle()
                        .fill(RadialGradient(colors: [orbColors[0].opacity(0.3), .clear],
                                            center: .center, startRadius: 60, endRadius: 120))
                        .frame(width: 240, height: 240)
                        .scaleEffect(pulse ? 1.08 : 0.95)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)

                    // Main orb
                    Circle()
                        .fill(RadialGradient(colors: orbColors,
                                            center: .init(x: 0.35, y: 0.3),
                                            startRadius: 5, endRadius: 90))
                        .frame(width: 160, height: 160)
                        .shadow(color: orbColors[1].opacity(0.6), radius: 30)
                        .scaleEffect(speech.isSpeaking ? (pulse ? 1.06 : 0.97) : 1.0)
                        .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: pulse)
                        .onTapGesture {
                            if speech.isRecording {
                                // stopRecording → cancels task → onRecordingFinished fires → onUserSpoke
                                speech.stopRecording()
                            } else if !speech.isSpeaking {
                                speech.toggleRecording()
                            } else {
                                speech.stopSpeaking()
                            }
                        }

                    // Waveform icon
                    Image(systemName: speech.isRecording ? "waveform" :
                                      speech.isSpeaking ? "speaker.wave.3.fill" :
                                      isTyping ? "ellipsis" : "mic.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                .onAppear { pulse = true; ripple = true }
                .onChange(of: speech.isRecording) { _ in ripple = speech.isRecording }

                // Status
                VStack(spacing: 12) {
                    Text(statusText)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal, 40)
                        .animation(.easeInOut(duration: 0.3), value: statusText)

                    // Auto-listen hint
                    if !speech.isRecording && !speech.isSpeaking && !isTyping {
                        Text("Tippe auf den Orb, um zu sprechen")
                            .font(.system(size: 13)).foregroundColor(.white.opacity(0.35))
                    }
                }

                Spacer()

                // End button
                Button {
                    speech.stopRecording()
                    speech.stopSpeaking()
                    dismiss()
                } label: {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.12)).frame(width: 64, height: 64)
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold)).foregroundColor(.white)
                    }
                }
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            // When isFinal fires naturally, send transcript
            speech.onRecordingFinished = { text in
                onUserSpoke(text)
            }
        }
        .onDisappear {
            speech.onSpeakingFinished = nil
            speech.onRecordingFinished = nil
        }
    }
}
