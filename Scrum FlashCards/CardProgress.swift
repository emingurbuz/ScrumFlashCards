//
//  CardProgress.swift
//  Scrum FlashCards
//

import Foundation
import SwiftData

@Model
final class CardProgress {
    @Attribute(.unique) var cardID: String
    var correctCount: Int
    var wrongCount: Int
    var consecutiveCorrect: Int
    var lastAnsweredAt: Date?

    init(cardID: String) {
        self.cardID = cardID
        self.correctCount = 0
        self.wrongCount = 0
        self.consecutiveCorrect = 0
        self.lastAnsweredAt = nil
    }

    var totalAttempts: Int { correctCount + wrongCount }

    /// A card is "mastered" after 3 consecutive correct answers — it drops out of Review.
    var isMastered: Bool { consecutiveCorrect >= 3 }

    /// Surfaces in Review when the user has answered it wrong and hasn't yet re-mastered it.
    var needsReview: Bool { wrongCount > 0 && !isMastered }

    func record(correct: Bool) {
        if correct {
            correctCount += 1
            consecutiveCorrect += 1
        } else {
            wrongCount += 1
            consecutiveCorrect = 0
        }
        lastAnsweredAt = .now
    }
}
