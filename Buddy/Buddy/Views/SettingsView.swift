//
//  SettingsView.swift
//  Buddy
//
//  Created by Torben Lehneke on 19.04.26.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("buddyName")           private var buddyName           = "Buddy"
    @AppStorage("buddyGender")         private var buddyGender         = ""
    @AppStorage("buddyVoiceGender")    private var buddyVoiceGender    = "female"
    @AppStorage("accentColorHex")      private var accentColorHex      = "6C63FF"
    @AppStorage("showMotivation")      private var showMotivation      = true
    @AppStorage("showProgressStrip")   private var showProgressStrip   = true
    @AppStorage("showDayOverview")     private var showDayOverview     = true
    @AppStorage("notificationsEnabled")private var notificationsEnabled = false
    @AppStorage("iCloudSyncEnabled")   private var iCloudSyncEnabled   = false

    @EnvironmentObject private var vm: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showResetAlert = false
    @State private var showOnboarding = false

    private let genders: [(label: String, image: String)] = [
        ("Mann", "Buddy-mann"),
        ("Frau",  "Buddy-frau")
    ]
    private let accentColors: [(name: String, hex: String)] = [
        ("Lila",    "6C63FF"),
        ("Pink",    "EC4899"),
        ("Mint",    "10B981"),
        ("Orange",  "F97316"),
        ("Blau",    "3B82F6"),
        ("Rot",     "EF4444"),
    ]

    var body: some View {
        NavigationView {
            List {

                // ── Buddy ──────────────────────────────────────────────
                Section {
                    HStack {
                        Label("Name", systemImage: "tag")
                        Spacer()
                        TextField("Buddy", text: $buddyName)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Label("Aussehen", systemImage: "person.crop.circle")
                        HStack(spacing: 12) {
                            ForEach(genders, id: \.image) { g in
                                GenderPickerCard(
                                    label: g.label,
                                    imageName: g.image,
                                    isSelected: buddyGender == g.image,
                                    accentHex: accentColorHex
                                ) {
                                    withAnimation(.spring(response: 0.35)) { buddyGender = g.image }
                                }
                            }
                        }
                    }

                    Button {
                        buddyName = ""
                        showOnboarding = true
                    } label: {
                        Label("Onboarding erneut anzeigen", systemImage: "arrow.counterclockwise")
                            .foregroundColor(Color(hex: accentColorHex))
                    }
                } header: {
                    Text("Buddy")
                }

                // ── Akzentfarbe ────────────────────────────────────────
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Akzentfarbe", systemImage: "paintpalette")
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                            ForEach(accentColors, id: \.hex) { c in
                                Button {
                                    withAnimation(.spring(response: 0.3)) { accentColorHex = c.hex }
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: c.hex))
                                            .frame(width: 36, height: 36)
                                        if accentColorHex == c.hex {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Erscheinungsbild")
                }

                // ── Startseite ─────────────────────────────────────────
                Section {
                    Toggle(isOn: $showMotivation) {
                        Label("Motivationsspruch anzeigen", systemImage: "quote.bubble")
                    }
                    .tint(Color(hex: accentColorHex))

                    Toggle(isOn: $showProgressStrip) {
                        Label("Tagesfortschritt anzeigen", systemImage: "chart.bar.fill")
                    }
                    .tint(Color(hex: accentColorHex))

                    Toggle(isOn: $showDayOverview) {
                        Label("Tagesübersicht anzeigen", systemImage: "sun.max.fill")
                    }
                    .tint(Color(hex: accentColorHex))
                } header: {
                    Text("Startseite")
                }

                // ── Buddy Chat / Stimme ────────────────────────────────
                Section {
                    HStack {
                        Label("Buddy-Stimme", systemImage: "waveform")
                        Spacer()
                        Picker("", selection: $buddyVoiceGender) {
                            Text("Frau").tag("female")
                            Text("Mann").tag("male")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 130)
                    }
                } header: {
                    Text("Chat & Sprache")
                }

                // ── Synchronisation ────────────────────────────────────
                Section {
                    Toggle(isOn: Binding(
                        get: { iCloudSyncEnabled },
                        set: { newValue in
                            iCloudSyncEnabled = newValue
                            vm.iCloudSyncEnabled = newValue
                        }
                    )) {
                        Label("iCloud Sync", systemImage: "icloud")
                    }
                    .tint(Color(hex: accentColorHex))
                    if iCloudSyncEnabled {
                        Text("Deine Daten werden automatisch auf all deinen Geräten synchronisiert.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Synchronisation")
                } footer: {
                    if iCloudSyncEnabled {
                        Text("Erfordert \u{201E}iCloud Key-Value Storage\u{201C} in den App-Einstellungen.")
                            .font(.footnote)
                    }
                }

                // ── Benachrichtigungen ─────────────────────────────────
                Section {
                    Toggle(isOn: $notificationsEnabled) {
                        Label("Tägliche Erinnerung", systemImage: "bell.badge")
                    }
                    .tint(Color(hex: accentColorHex))
                } header: {
                    Text("Benachrichtigungen")
                }

                // ── Daten ──────────────────────────────────────────────
                Section {
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Label("Alle Daten zurücksetzen", systemImage: "trash")
                    }
                } header: {
                    Text("Daten")
                }

                // ── App-Info ───────────────────────────────────────────
                Section {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("App")
                }
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: accentColorHex))
                }
            }
            .alert("Alles zurücksetzen?", isPresented: $showResetAlert) {
                Button("Zurücksetzen", role: .destructive) {
                    buddyName            = ""
                    buddyGender          = ""
                    accentColorHex       = "6C63FF"
                    showMotivation       = true
                    showProgressStrip    = true
                    showDayOverview      = true
                    notificationsEnabled = false
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Alle Einstellungen werden auf die Standardwerte zurückgesetzt.")
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            BuddyOnboardingView(buddyName: $buddyName)
        }
    }
}

private struct GenderPickerCard: View {
    let label: String
    let imageName: String
    let isSelected: Bool
    let accentHex: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(Color(.tertiarySystemGroupedBackground))
                        .frame(width: 80, height: 80)
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 70)
                }
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isSelected ? Color(hex: accentHex) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Color(hex: accentHex).opacity(0.1) : Color(.tertiarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isSelected ? Color(hex: accentHex) : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
