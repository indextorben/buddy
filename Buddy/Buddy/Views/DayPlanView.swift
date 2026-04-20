//  DayPlanView.swift
import SwiftUI

struct DayPlanView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("accentColorHex") private var accentHex = "6C63FF"

    @State private var plan: [DayPlanItem] = []

    private let typeColor: [DayPlanType: String] = [
        .task: "6C63FF", .habit: "FF6584", .appointment: "3B82F6", .pause: "9CA3AF"
    ]
    private let typeIcon: [DayPlanType: String] = [
        .task: "checkmark.circle.fill", .habit: "flame.fill",
        .appointment: "calendar", .pause: "cup.and.saucer.fill"
    ]

    var body: some View {
        NavigationView {
            Group {
                if plan.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 48)).foregroundColor(.secondary.opacity(0.4))
                        Text("Keine offenen Aufgaben oder Termine")
                            .font(.system(size: 15)).foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            ForEach(Array(plan.enumerated()), id: \.element.id) { idx, item in
                                HStack(alignment: .top, spacing: 12) {
                                    // Zeitachse
                                    VStack(spacing: 0) {
                                        Text(item.startTime.formatted(.dateTime.hour().minute()))
                                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                            .foregroundColor(.secondary)
                                            .frame(width: 44, alignment: .trailing)
                                        if idx < plan.count - 1 {
                                            Rectangle()
                                                .fill(Color(.separator).opacity(0.5))
                                                .frame(width: 1)
                                                .frame(maxHeight: .infinity)
                                                .padding(.top, 4)
                                        }
                                    }
                                    .frame(width: 44)

                                    // Karte
                                    let hex = typeColor[item.type] ?? "9CA3AF"
                                    VStack(alignment: .leading, spacing: 0) {
                                        HStack(spacing: 8) {
                                            Image(systemName: typeIcon[item.type] ?? "circle")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(Color(hex: hex))
                                            Text(item.title)
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(item.isDone ? .secondary : .primary)
                                                .strikethrough(item.isDone)
                                            Spacer()
                                            if let p = item.priority {
                                                priorityBadge(p)
                                            }
                                            Button {
                                                if let i = plan.firstIndex(where: { $0.id == item.id }) {
                                                    withAnimation { plan[i].isDone.toggle() }
                                                }
                                            } label: {
                                                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                                                    .font(.system(size: 20))
                                                    .foregroundColor(item.isDone ? Color(hex: hex) : Color(.tertiaryLabel))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        Text("\(item.duration) min · bis \(item.endTime.formatted(.dateTime.hour().minute()))")
                                            .font(.system(size: 11)).foregroundColor(.secondary)
                                            .padding(.top, 3)
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(Color(hex: hex).opacity(item.type == .pause ? 0.05 : 0.08))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .stroke(Color(hex: hex).opacity(0.2), lineWidth: 1)
                                            )
                                    )
                                    .padding(.bottom, 10)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Smarter Tagesplan")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation { plan = viewModel.generateDayPlan() }
                    } label: {
                        Label("Neu", systemImage: "arrow.clockwise")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: accentHex))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .fontWeight(.semibold).foregroundColor(Color(hex: accentHex))
                }
            }
            .onAppear { plan = viewModel.generateDayPlan() }
        }
    }

    @ViewBuilder private func priorityBadge(_ p: String) -> some View {
        let colors = ["Hoch": "EF4444", "Mittel": "F97316", "Niedrig": "10B981"]
        let hex = colors[p] ?? "9CA3AF"
        Text(p)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(Color(hex: hex))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Capsule().fill(Color(hex: hex).opacity(0.15)))
    }
}
