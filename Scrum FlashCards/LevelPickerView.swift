//
//  LevelPickerView.swift
//  Scrum FlashCards
//

import SwiftUI
import SwiftData

enum Route: Hashable {
    case practice(Level)
    case review
}

struct LevelPickerView: View {
    @Environment(\.modelContext) private var context
    @Query private var levelProgress: [LevelProgress]
    @Query private var cardProgress: [CardProgress]

    @State private var path: [Route] = []
    @State private var showResetAllConfirm = false
    @State private var levelToReset: Level?

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                background
                ScrollView {
                    VStack(spacing: 18) {
                        ScrumWordmarkView()
                            .padding(.top, 12)

                        VStack(spacing: 14) {
                            ForEach(Level.allCases, id: \.self) { level in
                                LevelRow(
                                    level: level,
                                    progress: progress(for: level),
                                    cardCount: Flashcard.cards(in: level).count,
                                    unlocked: isUnlocked(level),
                                    onTap: { tapLevel(level) },
                                    onResetRequest: { levelToReset = level }
                                )
                            }

                            ReviewRow(count: reviewCount, onTap: tapReview)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .overlay(alignment: .topTrailing) { settingsMenu }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .practice(let level):
                    PracticeView(level: level)
                case .review:
                    ReviewView()
                }
            }
            .alert("Reset progress?", isPresented: $showResetAllConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive, action: resetAll)
            } message: {
                Text("This erases all unlocked levels and card history. You'll start fresh from Basic.")
            }
            .alert(
                "Reset \(levelToReset?.title ?? "Level")?",
                isPresented: Binding(
                    get: { levelToReset != nil },
                    set: { if !$0 { levelToReset = nil } }
                )
            ) {
                Button("Cancel", role: .cancel) { levelToReset = nil }
                Button("Reset", role: .destructive) {
                    if let level = levelToReset {
                        ProgressStore(context: context).resetLevel(level)
                    }
                    levelToReset = nil
                }
            } message: {
                Text("Your attempts, in-progress run, and per-card history for this level will be erased. Other levels stay as they are.")
            }
            .onAppear {
                ProgressStore(context: context).ensureAllLevelProgressExists()
            }
        }
    }

    // MARK: - Background and menu

    private var background: some View {
        LinearGradient(
            colors: [Color.indigo, Color.purple, Color.pink.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var settingsMenu: some View {
        Menu {
            Button(role: .destructive) {
                showResetAllConfirm = true
            } label: {
                Label("Reset All Progress", systemImage: "arrow.counterclockwise")
            }
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .padding(10)
                .background(Circle().fill(.white.opacity(0.18)))
                .overlay(Circle().strokeBorder(.white.opacity(0.25), lineWidth: 1))
                .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
        }
        .padding(.trailing, 18)
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func progress(for level: Level) -> LevelProgress? {
        levelProgress.first { $0.levelRaw == level.rawValue }
    }

    private func isUnlocked(_ level: Level) -> Bool {
        if level == .basic { return true }
        return progress(for: level)?.isUnlocked ?? false
    }

    private var reviewCount: Int {
        cardProgress.filter { $0.wrongCount > 0 && $0.consecutiveCorrect < 3 }.count
    }

    private func tapLevel(_ level: Level) {
        guard isUnlocked(level) else { return }
        path.append(.practice(level))
    }

    private func tapReview() {
        guard reviewCount > 0 else { return }
        path.append(.review)
    }

    private func resetAll() {
        ProgressStore(context: context).resetAllProgress()
    }
}

// MARK: - Level row

private struct LevelRow: View {
    let level: Level
    let progress: LevelProgress?
    let cardCount: Int
    let unlocked: Bool
    let onTap: () -> Void
    let onResetRequest: () -> Void

    private var bestPct: Int { progress?.bestPercentageInt ?? 0 }
    private var passed: Bool { progress?.hasPassed ?? false }
    private var inProgress: Bool { progress?.hasInProgressAttempt ?? false }
    private var resumeIndex: Int { progress?.inProgressIndex ?? 0 }
    private var resumeTotal: Int { progress?.inProgressCardIDs.count ?? cardCount }

    private var hasResettableState: Bool {
        guard let progress else { return false }
        return progress.attemptsCount > 0 || progress.hasInProgressAttempt
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(level.accent.opacity(unlocked ? 1.0 : 0.4))
                        .frame(width: 56, height: 56)
                    Image(systemName: unlocked ? level.iconName : "lock.fill")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(level.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        if passed {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(level.accent)
                        }
                    }
                    Text(level.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        Text("\(cardCount) cards")
                        if let progress, progress.attemptsCount > 0 {
                            Text("·")
                            Text("Best \(bestPct)%")
                                .foregroundStyle(passed ? level.accent : .secondary)
                        }
                    }
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                    if inProgress {
                        Label("Resume \(resumeIndex + 1)/\(resumeTotal)", systemImage: "play.fill")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(level.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(level.accent.opacity(0.15)))
                            .padding(.top, 2)
                    }
                }

                Spacer()

                if hasResettableState {
                    Button(action: onResetRequest) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.callout.weight(.bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(Color(.secondarySystemBackground)))
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Reset \(level.title)")
                }

                Image(systemName: "chevron.right")
                    .font(.callout.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
            )
            .opacity(unlocked ? 1.0 : 0.65)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
    }
}

// MARK: - Review row

private struct ReviewRow: View {
    let count: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(count > 0 ? Color.red.opacity(0.85) : Color.gray.opacity(0.4))
                        .frame(width: 56, height: 56)
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Review")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(count > 0
                         ? "Cards you've missed will come back here until you master them."
                         : "Nothing to review — keep practicing!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if count > 0 {
                        Text("\(count) card\(count == 1 ? "" : "s") waiting")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.red)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.callout.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
            )
            .opacity(count > 0 ? 1.0 : 0.7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(count == 0)
    }
}
