//
//  BuddyOnboardingView.swift
//  Buddy
//
//  Created by Torben Lehneke on 19.04.26.
//

import SwiftUI

struct BuddyOnboardingView: View {
    @Binding var buddyName: String
    @AppStorage("buddyGender") private var buddyGender = ""

    @State private var step: Int = 1          // 1 = gender, 2 = name
    @State private var selectedGender = ""
    @State private var inputName = ""
    @State private var buddyFloat  = false
    @State private var sway        = false
    @State private var showContent = false
    @State private var confirmed   = false
    @FocusState private var fieldFocused: Bool

    private var trimmedName: String { inputName.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.06, blue: 0.25),
                    Color(red: 0.18, green: 0.11, blue: 0.43),
                    Color(red: 0.10, green: 0.06, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Blobs
            Circle()
                .fill(Color(red: 0.42, green: 0.39, blue: 1.0).opacity(0.25))
                .frame(width: 320, height: 320)
                .blur(radius: 70)
                .offset(x: -80, y: -200)
            Circle()
                .fill(Color(red: 0.65, green: 0.55, blue: 0.98).opacity(0.18))
                .frame(width: 200, height: 200)
                .blur(radius: 55)
                .offset(x: 130, y: 220)

            VStack(spacing: 0) {
                Spacer()

                // Buddy preview
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(red: 0.42, green: 0.39, blue: 1.0).opacity(0.3), .clear],
                                center: .center,
                                startRadius: 50,
                                endRadius: 150
                            )
                        )
                        .frame(width: 280, height: 280)
                        .scaleEffect(buddyFloat ? 1.08 : 0.95)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: buddyFloat)

                    Image(selectedGender.isEmpty ? "Buddy-mann" : selectedGender)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 210)
                        .rotationEffect(.degrees(sway ? 3 : -3), anchor: .bottom)
                        .animation(.easeInOut(duration: 2.3).repeatForever(autoreverses: true), value: sway)
                        .shadow(color: Color(red: 0.42, green: 0.39, blue: 1.0).opacity(0.5), radius: 28, x: 0, y: 10)
                        .offset(y: buddyFloat ? -10 : 0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: buddyFloat)
                        .transition(.scale.combined(with: .opacity))
                        .id(selectedGender)
                }
                .onAppear { buddyFloat = true; sway = true }

                Spacer().frame(height: 28)

                // Step indicator
                HStack(spacing: 8) {
                    ForEach(1...2, id: \.self) { i in
                        Capsule()
                            .fill(step >= i ? Color(red: 0.65, green: 0.55, blue: 0.98) : Color.white.opacity(0.2))
                            .frame(width: step == i ? 24 : 8, height: 6)
                            .animation(.spring(response: 0.4), value: step)
                    }
                }
                .padding(.bottom, 20)

                // Content per step
                Group {
                    if step == 1 {
                        genderStep
                    } else {
                        nameStep
                    }
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 24)
                .animation(.spring(response: 0.55).delay(0.1), value: showContent)

                Spacer()

                Text("Du kannst alles später in den Einstellungen ändern.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.25))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 32)
            }
        }
        .onAppear { showContent = true }
    }

    // MARK: Step 1 – Gender

    private var genderStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Hallo! Ich bin Buddy.")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Wähle ein Aussehen für mich:")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(red: 0.77, green: 0.71, blue: 0.99))
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)

            HStack(spacing: 16) {
                GenderCard(
                    label: "Mann",
                    imageName: "Buddy-mann",
                    isSelected: selectedGender == "Buddy-mann"
                ) { withAnimation(.spring(response: 0.4)) { selectedGender = "Buddy-mann" } }

                GenderCard(
                    label: "Frau",
                    imageName: "Buddy-frau",
                    isSelected: selectedGender == "Buddy-frau"
                ) { withAnimation(.spring(response: 0.4)) { selectedGender = "Buddy-frau" } }
            }
            .padding(.horizontal, 28)

            Button {
                guard !selectedGender.isEmpty else { return }
                withAnimation(.spring(response: 0.45)) {
                    showContent = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        step = 2
                        showContent = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { fieldFocused = true }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text("Weiter")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Group {
                        if selectedGender.isEmpty {
                            AnyView(Color.white.opacity(0.12))
                        } else {
                            AnyView(LinearGradient(
                                colors: [Color(red: 0.42, green: 0.39, blue: 1.0), Color(red: 0.65, green: 0.55, blue: 0.98)],
                                startPoint: .leading, endPoint: .trailing
                            ))
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(
                    color: selectedGender.isEmpty ? .clear : Color(red: 0.42, green: 0.39, blue: 1.0).opacity(0.45),
                    radius: 12, x: 0, y: 4
                )
            }
            .disabled(selectedGender.isEmpty)
            .padding(.horizontal, 28)
        }
    }

    // MARK: Step 2 – Name

    private var nameStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Wie soll ich heißen?")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Gib mir einen Namen, den du magst.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(red: 0.77, green: 0.71, blue: 0.99))
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)

            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "pencil.and.sparkles")
                        .foregroundColor(Color(red: 0.65, green: 0.55, blue: 0.98))
                        .font(.system(size: 18))
                    TextField("z.B. Max, Luna, Luca…", text: $inputName)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .focused($fieldFocused)
                        .submitLabel(.done)
                        .onSubmit { confirm() }
                        .tint(Color(red: 0.65, green: 0.55, blue: 0.98))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(
                                    fieldFocused
                                        ? Color(red: 0.65, green: 0.55, blue: 0.98)
                                        : Color.white.opacity(0.15),
                                    lineWidth: 1.5
                                )
                        )
                )

                Button(action: confirm) {
                    HStack(spacing: 8) {
                        Text(trimmedName.isEmpty ? "Weiter" : "Los geht's, \(trimmedName)! 🎉")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                        if trimmedName.isEmpty {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.42, green: 0.39, blue: 1.0), Color(red: 0.65, green: 0.55, blue: 0.98)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: Color(red: 0.42, green: 0.39, blue: 1.0).opacity(0.45), radius: 12, x: 0, y: 4)
                    .scaleEffect(confirmed ? 0.97 : 1)
                    .animation(.spring(response: 0.3), value: confirmed)
                }
            }
            .padding(.horizontal, 28)
        }
    }

    private func confirm() {
        confirmed = true
        buddyGender = selectedGender
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
            buddyName = trimmedName.isEmpty ? "Buddy" : trimmedName
        }
    }
}

// MARK: - Gender Card

private struct GenderCard: View {
    let label: String
    let imageName: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 130, height: 130)
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                }
                .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 4)

                Text(label)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(isSelected ? Color(red: 0.65, green: 0.55, blue: 0.98) : .white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(isSelected ? 0.18 : 0.10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(
                                isSelected ? Color(red: 0.65, green: 0.55, blue: 0.98) : Color.white.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
            .shadow(
                color: isSelected ? Color(red: 0.42, green: 0.39, blue: 1.0).opacity(0.4) : .clear,
                radius: 14, x: 0, y: 4
            )
        }
        .buttonStyle(.plain)
    }
}
