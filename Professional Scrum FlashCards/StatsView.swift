//
//  StatsView.swift
//  Scrum FlashCards
//

import SwiftUI
import SwiftData

struct StatsView: View {
    @Query private var globalStats: [GlobalStats]
    @Query private var levelProgress: [LevelProgress]
    @Query private var cardProgress: [CardProgress]
    
    @Environment(\.dismiss) private var dismiss
    
    var stats: GlobalStats? { globalStats.first }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    summarySection
                    levelDistributionSection
                    masterySection
                    
                    Text("Aggregated statistics are synced with the developer dashboard to improve question quality.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                }
                .padding()
            }
            .navigationTitle("Your Stats")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overall Usage")
                .font(.headline)
                .padding(.leading, 4)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(title: "Practice Time", value: formatTime(stats?.totalSecondsPracticed ?? 0), icon: "clock.fill", color: .blue)
                StatCard(title: "Sessions", value: "\(stats?.totalSessionsCount ?? 0)", icon: "play.circle.fill", color: .green)
                StatCard(title: "Total Resets", value: "\(stats?.totalResetsCount ?? 0)", icon: "arrow.counterclockwise.circle.fill", color: .orange)
                StatCard(title: "Cards Seen", value: "\(cardProgress.count) / \(Flashcard.all.count)", icon: "rectangle.stack.fill", color: Color(red: 0.00, green: 0.59, blue: 0.65))
            }
        }
    }
    
    private var levelDistributionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Level Progress")
                .font(.headline)
                .padding(.leading, 4)
            
            VStack(spacing: 1) {
                ForEach(Level.allCases) { level in
                    let lp = levelProgress.first(where: { $0.levelRaw == level.rawValue })
                    HStack {
                        Label(level.title, systemImage: level.iconName)
                            .foregroundStyle(level.accent)
                        Spacer()
                        if lp?.hasPassed == true {
                            Text("Mastered")
                                .font(.caption.bold())
                                .foregroundStyle(level.accent)
                        } else if lp?.isUnlocked == true {
                            Text("In Progress")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var masterySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mastery")
                .font(.headline)
                .padding(.leading, 4)
            
            let masteredCount = cardProgress.filter { $0.isMastered }.count
            let totalCards = Flashcard.all.count
            let masteryPct = totalCards > 0 ? Double(masteredCount) / Double(totalCards) : 0
            
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(masteredCount) / \(totalCards) Cards Mastered")
                            .font(.subheadline.bold())
                        Text("Mastered after 3 correct answers in a row")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(Int(masteryPct * 100))%")
                        .font(.title2.bold())
                        .foregroundStyle(Color(red: 0.00, green: 0.59, blue: 0.65))
                }
                
                ProgressView(value: masteryPct)
                    .tint(Color(red: 0.00, green: 0.59, blue: 0.65))
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        if seconds < 60 && seconds > 0 {
            return "\(Int(seconds))s"
        }
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
