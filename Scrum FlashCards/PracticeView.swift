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
    @State private var showCompletion = false
    @State private var didLoad = false

    var body: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                if !cards.isEmpty && index < cards.count {
                    FlashcardView(
                        card: cards[index],
                        index: index,
                        total: cards.count,
                        onAnswer: handleAnswer,
                        onNext: advance
                    )
                    .id(cards[index].id)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
                Spacer(minLength: 0)
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
            colors: [Color.indigo, level.accent.opacity(0.7), Color.purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Loading

    private func loadOnce() {
        guard !didLoad else { return }
        didLoad = true
        let store = ProgressStore(context: context)
        let lp = store.levelProgress(for: level)

        if lp.hasInProgressAttempt,
           let resumed = resumeDeck(from: lp.inProgressCardIDs),
           lp.inProgressIndex >= 0,
           lp.inProgressIndex <= resumed.count {
            cards = resumed
            index = lp.inProgressIndex
            correctCount = lp.inProgressCorrectCount
            if index >= cards.count {
                // Saved attempt was effectively complete — finalize cleanly.
                finalize(store: store)
            }
        } else {
            startFreshAttempt(store: store)
        }
    }

    /// Rebuild the deck from saved IDs. If any card has been removed (or moved out of
    /// this level) since the attempt was saved, returns nil so we restart cleanly.
    private func resumeDeck(from ids: [String]) -> [Flashcard]? {
        let byID = Dictionary(uniqueKeysWithValues: Flashcard.cards(in: level).map { ($0.id, $0) })
        let resolved = ids.compactMap { byID[$0] }
        guard resolved.count == ids.count, !resolved.isEmpty else { return nil }
        return resolved
    }

    private func startFreshAttempt(store: ProgressStore) {
        let deck = Flashcard.cards(in: level).shuffled()
        cards = deck
        index = 0
        correctCount = 0
        let lp = store.levelProgress(for: level)
        lp.startAttempt(cardIDs: deck.map(\.id))
    }

    // MARK: - Actions

    private func handleAnswer(_ correct: Bool) {
        let store = ProgressStore(context: context)
        store.recordAnswer(card: cards[index], correct: correct)
        if correct { correctCount += 1 }
        // Persist running tally; the index updates on advance().
        let lp = store.levelProgress(for: level)
        lp.inProgressCorrectCount = correctCount
    }

    private func advance() {
        let store = ProgressStore(context: context)
        let lp = store.levelProgress(for: level)
        if index + 1 < cards.count {
            index += 1
            lp.inProgressIndex = index
        } else {
            finalize(store: store)
        }
    }

    private func finalize(store: ProgressStore) {
        // recordAttempt also clears the in-progress state.
        store.finishLevelAttempt(level: level, correct: correctCount, total: cards.count)
        showCompletion = true
    }

    private func restart() {
        showCompletion = false
        let store = ProgressStore(context: context)
        startFreshAttempt(store: store)
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
