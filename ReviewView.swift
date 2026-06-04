//
//  ReviewView.swift
//  Scrum FlashCards
//

import SwiftUI
import SwiftData

struct ReviewView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var cards: [Flashcard] = []
    @State private var index = 0
    @State private var didLoad = false

    var body: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()

            if !didLoad {
                ProgressView().tint(.white)
            } else if cards.isEmpty {
                emptyState
            } else if index < cards.count {
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
                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: index)
            } else {
                doneState
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Review")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
        .onAppear(perform: loadOnce)
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color.indigo, Color.red.opacity(0.6), Color.purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(.white)
            Text("All caught up")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            Text("Cards you've missed in practice will show up here until you master them.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button(action: { dismiss() }) {
                Text("Back to Levels")
                    .font(.headline)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(.white))
                    .foregroundStyle(Color.indigo)
            }
            .padding(.top, 6)
        }
    }

    private var doneState: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(.white)
            Text("Nice work")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            Text("Review session complete. Mastered cards will drop off the list.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button(action: { dismiss() }) {
                Text("Done")
                    .font(.headline)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(.white))
                    .foregroundStyle(Color.indigo)
            }
            .padding(.top, 6)
        }
    }

    private func loadOnce() {
        guard !didLoad else { return }
        let store = ProgressStore(context: context)
        let ids = Set(store.cardIDsNeedingReview())
        cards = Flashcard.cards(matching: ids).shuffled()
        didLoad = true
    }

    private func handleAnswer(_ correct: Bool) {
        let store = ProgressStore(context: context)
        store.recordAnswer(card: cards[index], correct: correct)
    }

    private func advance() {
        index += 1
    }
}
