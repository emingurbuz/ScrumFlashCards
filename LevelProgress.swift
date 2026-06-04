//
//  LevelProgress.swift
//  Scrum FlashCards
//

import Foundation
import SwiftData

@Model
final class LevelProgress {
    @Attribute(.unique) var levelRaw: String
    var isUnlocked: Bool
    var bestPercentage: Double
    var lastAttemptCorrect: Int
    var lastAttemptTotal: Int
    var attemptsCount: Int

    // Resume state for an in-progress attempt. Empty `inProgressCardIDs` means no active attempt.
    var inProgressCardIDs: [String]
    var inProgressIndex: Int
    var inProgressCorrectCount: Int

    init(level: Level, isUnlocked: Bool = false) {
        self.levelRaw = level.rawValue
        self.isUnlocked = isUnlocked
        self.bestPercentage = 0
        self.lastAttemptCorrect = 0
        self.lastAttemptTotal = 0
        self.attemptsCount = 0
        self.inProgressCardIDs = []
        self.inProgressIndex = 0
        self.inProgressCorrectCount = 0
    }

    var hasInProgressAttempt: Bool { !inProgressCardIDs.isEmpty }

    func startAttempt(cardIDs: [String]) {
        inProgressCardIDs = cardIDs
        inProgressIndex = 0
        inProgressCorrectCount = 0
    }

    func clearAttempt() {
        inProgressCardIDs = []
        inProgressIndex = 0
        inProgressCorrectCount = 0
    }

    var level: Level? { Level(rawValue: levelRaw) }

    var bestPercentageInt: Int { Int((bestPercentage * 100).rounded()) }

    var hasPassed: Bool {
        guard let level else { return false }
        return bestPercentage >= level.passingPercentage
    }

    func recordAttempt(correct: Int, total: Int) {
        guard total > 0 else { return }
        lastAttemptCorrect = correct
        lastAttemptTotal = total
        attemptsCount += 1
        let pct = Double(correct) / Double(total)
        if pct > bestPercentage {
            bestPercentage = pct
        }
        clearAttempt()
    }
}
