//
//  PracticeView.swift
//  Scrum FlashCards
//

import SwiftUI
import SwiftData

struct PracticeView: View {
    let level: Level

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var cards: [Flashcard] = []
    @State private var index = 0
    @State private var correctCount = 0
    @State private var incorrectCount = 0
    @State private var showCompletion = false
    @State private var didLoad = false
    @State private var startTime = Date()
    @State private var cardStartTime = Date()
    @State private var currentMode: FlashcardView.Mode = .learning

    var body: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                if !cards.isEmpty && index < cards.count {
                    let progress = ProgressStore(context: context).cardProgress(for: cards[index].id)
                    FlashcardView(
                        card: cards[index],
                        index: index,
                        total: cards.count,
                        correctCount: correctCount,
                        incorrectCount: incorrectCount,
                        isMastered: progress.isMastered,
                        mode: currentMode,
                        onAnswer: handleAnswer,
                        onNext: advance
                    )
                    .id(cards[index].id)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                        removal: .move(edge: .leading).combined(with: .opacity).combined(with: .scale(scale: 1.05))
                    ))
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: index)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(level.title)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
        .onAppear(perform: loadOnce)
        .onDisappear(perform: handleExit)
        .sheet(isPresented: $showCompletion) {
            CompletionSheet(
                level: level,
                correct: correctCount,
                total: cards.count,
                onClose: {
                    showCompletion = false
                    dismiss()
                },
                onRetry: restart
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color.black, level.accent.opacity(0.3), Color.black],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Loading

    private func loadOnce() {
        guard !didLoad else { return }
        didLoad = true
        startTime = Date()
        cardStartTime = Date()
        let store = ProgressStore(context: context)
        let lp = store.levelProgress(for: level)

        TelemetryManager.shared.trackSessionStart(level: level.rawValue)

        if lp.hasInProgressAttempt,
           let resumed = resumeDeck(from: lp.inProgressCardIDs),
           lp.inProgressIndex >= 0,
           lp.inProgressIndex <= resumed.count {
            cards = resumed
            index = lp.inProgressIndex
            correctCount = lp.inProgressCorrectCount
            incorrectCount = index - correctCount
            if index >= cards.count {
                finalize(store: store)
            }
        } else {
            startFreshAttempt(store: store)
        }
        updateCurrentMode()
    }

    private func resumeDeck(from ids: [String]) -> [Flashcard]? {
        let byID = Dictionary(uniqueKeysWithValues: Flashcard.cards(in: level).map { ($0.id, $0) })
        let resolved = ids.compactMap { byID[$0] }
        guard resolved.count == ids.count, !resolved.isEmpty else { return nil }
        return resolved
    }

    private func startFreshAttempt(store: ProgressStore) {
        let allCards = Flashcard.cards(in: level)
        let lp = store.levelProgress(for: level)
        
        let windowSize = 50
        let rotationStep = 25
        let startIndex = (lp.attemptsCount * rotationStep) % max(1, allCards.count)
        
        var selectedCards: [Flashcard] = []
        for i in 0..<windowSize {
            let index = (startIndex + i) % max(1, allCards.count)
            selectedCards.append(allCards[index])
        }
        
        let deck = selectedCards.shuffled()
        cards = deck
        index = 0
        correctCount = 0
        incorrectCount = 0
        lp.startAttempt(cardIDs: deck.map(\.id))
    }

    // MARK: - Actions

    private func handleAnswer(_ correct: Bool) {
        let cardTime = Date().timeIntervalSince(cardStartTime)
        let store = ProgressStore(context: context)
        store.recordAnswer(card: cards[index], correct: correct)
        
        // Intelligent Metric: Track card failure/success for difficulty heatmap
        TelemetryManager.shared.trackCardAnswer(
            cardID: cards[index].id,
            level: level.rawValue,
            isCorrect: correct,
            timeTaken: cardTime
        )
        
        if correct {
            correctCount += 1
        } else {
            incorrectCount += 1
        }
        let lp = store.levelProgress(for: level)
        lp.inProgressCorrectCount = correctCount
    }

    private func advance() {
        cardStartTime = Date() // Reset for next card
        let store = ProgressStore(context: context)
        let lp = store.levelProgress(for: level)
        if index + 1 < cards.count {
            index += 1
            lp.inProgressIndex = index
            updateCurrentMode()
        } else {
            finalize(store: store)
        }
    }

    private func finalize(store: ProgressStore) {
        let elapsed = Date().timeIntervalSince(startTime)
        recordProgress()
        store.finishLevelAttempt(level: level, correct: correctCount, total: cards.count)
        
        // Intelligent Metric: Track session completion
        TelemetryManager.shared.trackSessionEnd(
            level: level.rawValue,
            duration: elapsed,
            correct: correctCount,
            total: cards.count,
            finished: true
        )
        
        showCompletion = true
    }

    private func handleExit() {
        let elapsed = Date().timeIntervalSince(startTime)
        if index < cards.count && !showCompletion {
            // Intelligent Metric: Track abandonment/churn
            TelemetryManager.shared.trackSessionEnd(
                level: level.rawValue,
                duration: elapsed,
                correct: correctCount,
                total: cards.count,
                finished: false
            )
        }
        recordProgress()
    }

    private func recordProgress() {
        let elapsed = Date().timeIntervalSince(startTime)
        guard elapsed > 1 else { return } // Avoid micro-sessions
        
        let store = ProgressStore(context: context)
        store.addPracticeTime(elapsed)
        
        // Reset startTime so if they continue/restart, we don't double-count
        startTime = Date()
    }

    private func restart() {
        showCompletion = false
        startTime = Date()
        cardStartTime = Date()
        let store = ProgressStore(context: context)
        startFreshAttempt(store: store)
        updateCurrentMode()
        TelemetryManager.shared.trackSessionStart(level: level.rawValue)
    }

    private func updateCurrentMode() {
        guard index < cards.count else { return }
        let progress = ProgressStore(context: context).cardProgress(for: cards[index].id)
        currentMode = progress.totalAttempts > 0 ? .reviewing : .learning
    }
}

// MARK: - Completion sheet

private struct CompletionSheet: View {
    let level: Level
    let correct: Int
    let total: Int
    let onClose: () -> Void
    let onRetry: () -> Void

    private var pct: Int { total > 0 ? Int((Double(correct) / Double(total) * 100).rounded()) : 0 }
    private var passed: Bool { total > 0 && Double(correct) / Double(total) >= level.passingPercentage }
    private var unlockedNext: Bool { passed && level.next != nil }

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: passed ? "checkmark.seal.fill" : "arrow.counterclockwise.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(passed ? level.accent : .orange)

            Text(passed ? "Level passed!" : "Almost there")
                .font(.title2.weight(.bold))

            Text("You answered \(correct) out of \(total) correctly (\(pct)%).")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if unlockedNext, let next = level.next {
                Label("\(next.title) unlocked", systemImage: "lock.open.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(next.accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(next.accent.opacity(0.15))
                    )
            } else if !passed {
                Text("You need \(Int(level.passingPercentage * 100))% to unlock the next level.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                Button(action: onRetry) {
                    Text("Try Again")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(level.accent))
                        .foregroundStyle(.white)
                }
                Button(action: onClose) {
                    Text("Back to Levels")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 6)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
